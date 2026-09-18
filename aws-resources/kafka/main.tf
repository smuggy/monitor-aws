locals {
  kafka_cluster_count = 3
  kafka_server_names  = formatlist("kafka-%02d", range(local.kafka_cluster_count))
  kafka_hosts         = formatlist("%s ansible_host=%s", local.kafka_server_names, module.brokers.*.public_ip)
  kafka_host_group    = join("\n", local.kafka_hosts)
}

data aws_ami ubuntu {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-aws-base-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module brokers {
  source  = "app.terraform.io/podspace/base/aws//compute/instance"
  version = "0.3.0"

  count         = local.kafka_cluster_count
  az            = var.az_list[count.index]
  subnet        = lookup(var.public_subnet_map, var.az_list[count.index])
  sec_groups    = [aws_security_group.kafka_security_group.id]
  app           = "kfk"
  volume_size   = 4
  volume_type   = "gp3"
  key_name      = var.key_pair_name
  region        = var.region
  instance_type = "t3a.small"
  ami_id        = data.aws_ami.ubuntu.id

  name_zone_id    = var.internal_zone_id
  reverse_zone_id = var.reverse_zone_id
}

module node_dns_record {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"

  count   = local.kafka_cluster_count
  name    = local.kafka_server_names[count.index]
  zone_id = var.internal_zone_id
  records = [module.brokers.*.private_ip[count.index]]
}

module kafka_dns_record {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"
  count   = local.kafka_cluster_count == 0 ? 0 : 1

  zone_id = var.internal_zone_id
  name    = "kafka"
  records = module.brokers.*.private_ip
}

module kafka_dns_public {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"
  count   = local.kafka_cluster_count == 0 ? 0 : 1

  zone_id = var.public_zone_id
  name    = "kafka"
  records = module.brokers.*.public_ip
}

module node_dns_public {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"

  count   = local.kafka_cluster_count
  name    = local.kafka_server_names[count.index]
  zone_id = var.public_zone_id
  records = [module.brokers.*.public_ip[count.index]]
}

resource aws_security_group kafka_security_group {
  name   = "kafka_sg_01"
  vpc_id = var.vpc_id
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

resource aws_security_group_rule kafka_ports_consul {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 8300
  to_port           = 8301
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