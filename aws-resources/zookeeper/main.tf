locals {
  zookeeper_server_names  = formatlist("zoo-%02d", range(var.cluster_count))
  zookeeper_hosts         = formatlist("%s ansible_host=%s", local.zookeeper_server_names, module.brokers.*.public_ip)
  zookeeper_host_group    = join("\n", local.zookeeper_hosts)
  zookeeper_servers       = formatlist("server.%d=%s:2888:3888",
    range(1, var.cluster_count + 1),
    local.zookeeper_server_names)
  id_map                  = formatlist("%s: %d", local.zookeeper_server_names, range(1, var.cluster_count + 1))
}

module brokers {
  source  = "app.terraform.io/podspace/base/aws//compute/instance"
  version = "0.3.0"

  count         = var.cluster_count
  az            = element(var.az_list, count.index)
  subnet        = lookup(var.public_subnet_map, element(var.az_list, count.index))
  sec_groups    = [aws_security_group.security_group.id]
  app           = "zk"
  volume_size   = 4
  volume_type   = "gp3"
  key_name      = var.key_pair_name
  region        = var.region
  instance_type = "t3a.small"

  name_zone_id    = var.internal_zone_id
  reverse_zone_id = var.reverse_zone_id
}

module node_dns_record {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"

  count   = var.cluster_count
  name    = element(local.zookeeper_server_names, count.index)
  zone_id = var.internal_zone_id
  records = [element(module.brokers.*.private_ip, count.index)]
}

module kafka_dns_record {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"
  count   = var.cluster_count == 0 ? 0 : 1

  zone_id = var.internal_zone_id
  name    = "zookeeper"
  records = module.brokers.*.private_ip
}

module dns_public {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"
  count   = var.cluster_count == 0 ? 0 : 1

  zone_id = var.public_zone_id
  name    = "zookeeper"
  records = module.brokers.*.public_ip
}

resource aws_security_group security_group {
  name   = "zookeeper_sg_01"
  vpc_id = var.vpc_id
}

resource aws_security_group_rule outbound_ports {
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
}

resource aws_security_group_rule zookeeper_client_port {
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 2181
  to_port           = 2181
}

resource aws_security_group_rule zookeeper_ports_consul {
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 8300
  to_port           = 8301
}

resource aws_security_group_rule zookeeper_ssh {
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
}

resource aws_security_group_rule zookeeper_self_all {
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  self              = true
}

output zookeeper_ips {
  value = module.brokers.*.public_ip
}

# TODO:
#provider: aws
#region: us-east-2
#node_id_map:
#kafka-00.podspace.internal: 1
#kafka-01.podspace.internal: 2
#kafka-02.podspace.internal: 3