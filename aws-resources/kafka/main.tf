locals {
  kafka_cluster_count = 3
  kafka_server_names  = formatlist("kafka-%02d", range(local.kafka_cluster_count))
  kafka_cert_names    = formatlist("kafka-%02d.podspace.net", range(local.kafka_cluster_count))
  kafka_hosts         = formatlist("%s ansible_host=%s", local.kafka_server_names, module.brokers.*.public_ip)
  kafka_host_group    = join("\n", local.kafka_hosts)
  schema_registry_host_group = format("schema-registry ansible_host=%s\n", module.registry.public_ip)
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

#==========================================================================
# Kafka brokers
module brokers {
  source  = "app.terraform.io/podspace/base/aws//compute/instance"
  version = "0.3.0"

  count         = local.kafka_cluster_count
  az            = var.az_list[count.index]
  subnet        = lookup(var.public_subnet_map, var.az_list[count.index])
  sec_groups    = [aws_security_group.kafka_security_group.id]
  app           = "kfk"
  server_type   = "brk"
  volume_size   = 4
  volume_type   = "gp3"
  key_name      = var.key_pair_name
  region        = var.region
  instance_type = var.instance_type
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
#==========================================================================

#==========================================================================
# Schema Registry
module registry {
  source  = "app.terraform.io/podspace/base/aws//compute/instance"
  version = "0.3.0"

  az            = var.az_list[0]
  subnet        = lookup(var.public_subnet_map, var.az_list[0])
  sec_groups    = [aws_security_group.kafka_security_group.id]
  app           = "kfk"
  server_type   = "sry"
  key_name      = var.key_pair_name
  region        = var.region
  instance_type = var.instance_type
  ami_id        = data.aws_ami.ubuntu.id

  name_zone_id    = var.internal_zone_id
  reverse_zone_id = var.reverse_zone_id
}

module sr_node_dns_private {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"

  name    = "schema-registry"
  zone_id = var.internal_zone_id
  records = [module.registry.private_ip]
}

module sr_node_dns_public {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.3.0"
  name    = "schema-registry"
  zone_id = var.public_zone_id
  records = [module.registry.public_ip]
}
#==========================================================================

#==========================================================================
# Security group definition
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

resource aws_security_group_rule app_test_port {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 8080
  to_port           = 8081
}

resource aws_security_group_rule schema_registry_port {
  security_group_id = aws_security_group.kafka_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8081
  to_port           = 8081
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
#==========================================================================

locals {
  raft_id = substr(base64encode(replace(random_uuid.raft_id.result, "-", "")), 0, 22)
}

resource random_uuid raft_id {
}

#==========================================================================
# External certificate
data local_file external_ca {
  filename = "${path.root}/../../vpcs/secrets/podspace_ca_cert.pem"
}

resource random_password pass {
  length  = 12
  special = false
  numeric = true
  upper   = true
  lower   = true
}

module cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "kafka.podspace.net"
  alternate_names = local.kafka_cert_names
  alternate_ips   = module.brokers.*.public_ip
  ca_private_key  = file("${path.root}/../../vpcs/secrets/podspace_ca_key.pem")
  ca_certificate  = file("${path.root}/../../vpcs/secrets/podspace_ca_cert.pem")
}

resource local_file external_ca {
  filename        = "${path.root}/../secrets/external_ca.pem"
  content         = data.local_file.external_ca.content
  file_permission = "0644"
}

resource local_file external_cert {
  filename        = "${path.root}/../secrets/external_cert.pem"
  content         = module.cert.certificate_pem
  file_permission = "0644"
}

resource local_sensitive_file external_key {
  filename        = "${path.root}/../secrets/external_key.pem"
  file_permission = "0400"
  content         = module.cert.private_key
}

resource local_sensitive_file read_secret {
  filename        = "${path.root}/../secrets/jks_password"
  file_permission = "0400"
  content         = random_password.pass.result
}
#==========================================================================
