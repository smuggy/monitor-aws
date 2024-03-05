locals {
  kafka_cluster_count = 3
  kafka_server_names  = formatlist("kafka-%02d", range(local.kafka_cluster_count))
  kafka_hosts         = formatlist("%s ansible_host=%s", local.kafka_server_names, module.brokers.*.public_ip)
  kafka_host_group    = join("\n", local.kafka_hosts)
}

module brokers {
  source  = "app.terraform.io/podspace/base/aws//compute/instance"
  version = "0.1.0"

  count         = local.kafka_cluster_count
  az            = element(local.az_list, count.index)
  subnet        = lookup(local.public_subnet_map, element(local.az_list, count.index))
  sec_groups    = [aws_security_group.kafka_security_group.id]
  app           = "kfk"
  volume_size   = 4
  key_name      = module.utility_key_pair.key_pair_name
  region        = local.region
  instance_type = "t3a.small"

  name_zone_id    = data.aws_route53_zone.internal.zone_id
  reverse_zone_id = data.aws_route53_zone.reverse.zone_id
}

module node_dns_record {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.1.0"

  count   = local.kafka_cluster_count
  name    = element(local.kafka_server_names, count.index)
  zone_id = data.aws_route53_zone.internal.zone_id
  records = [element(module.brokers.*.private_ip, count.index)]
}

module kafka_dns_record {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.1.0"

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "kafka"
  records = module.brokers.*.private_ip
}

#module kafka_dns_public {
#  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
#  version = "0.1.0"
#
#  zone_id = data.aws_route53_zone.public.zone_id
#  name    = "kafka"
#  records = module.brokers.*.public_ip
#}

resource aws_security_group kafka_security_group {
  name   = "kafka_sg_01"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule kafka_outbound_ports {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "egress"
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
}

resource aws_security_group_rule kafka_ports {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9000
  to_port           = 9999
}

resource aws_security_group_rule kafka_ssh {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
}

resource aws_security_group_rule kafka_self_all {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  self              = true
}

resource local_file kafka_group_file {
  filename        = "../infra/group_vars/kafka_servers"
  content         = templatefile("templates/kafka_groups_vars.tpl",
    {
      region     = local.region
      raft_id    = local.raft_id
    })
  file_permission = 0644
}

output kafka_ips {
  value = module.brokers.*.public_ip
}

locals {
  raft_id = substr(base64encode(replace(random_uuid.raft_id.result, "-", "")), 0, 22)
}

resource random_uuid raft_id {
}

# TODO:
#provider: aws
#region: us-east-2
#node_id_map:
#kafka-00.podspace.internal: 1
#kafka-01.podspace.internal: 2
#kafka-02.podspace.internal: 3