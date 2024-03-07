locals {
  app_server_name  = "app-01"
  app_hosts         = [format("%s ansible_host=%s", local.app_server_name, module.app.public_ip)]
  app_host_group    = join("\n", local.app_hosts)
}

module app {
  source  = "app.terraform.io/podspace/base/aws//compute/instance"
  version = "0.1.0"

  az            = element(local.az_list, 0)
  subnet        = lookup(local.public_subnet_map, element(local.az_list, 0))
  sec_groups    = [aws_security_group.app_security_group.id]
  app           = "app"
  volume_size   = 4
  key_name      = module.utility_key_pair.key_pair_name
  region        = local.region
  instance_type = "t3a.small"

  name_zone_id    = data.aws_route53_zone.internal.zone_id
  reverse_zone_id = data.aws_route53_zone.reverse.zone_id
}

module app_node_dns {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.1.0"

  name    = local.app_server_name
  zone_id = data.aws_route53_zone.internal.zone_id
  records = [module.app.private_ip]
}

module app_internal_dns {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.1.0"

  name    = "app"
  zone_id = data.aws_route53_zone.internal.zone_id
  records = [module.app.private_ip]
}

module app_public_dns {
  source  = "app.terraform.io/podspace/base/aws//network/route53/a_record"
  version = "0.1.0"

  zone_id = data.aws_route53_zone.public.zone_id
  name    = "app"
  records = [module.app.public_ip]
}

resource aws_security_group app_security_group {
  name   = "app_sg_01"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule app_outbound_ports {
  security_group_id = aws_security_group.app_security_group.id
  type              = "egress"
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
}

#resource aws_security_group_rule kafka_ports {
#  security_group_id = aws_security_group.kafka_security_group.id
#  type              = "ingress"
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  from_port         = 9000
#  to_port           = 9999
#}

resource aws_security_group_rule app_ssh {
  security_group_id = aws_security_group.app_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
}

resource aws_security_group_rule app_http_alt {
  security_group_id = aws_security_group.app_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8080
  to_port           = 8080
}

resource aws_security_group_rule app_ne {
  security_group_id = aws_security_group.app_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 9100
  to_port           = 9100
}

resource aws_security_group_rule app_consul {
  security_group_id = aws_security_group.app_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 8300
  to_port           = 8301
}

output app_ip {
  value = module.app.public_ip
}

resource local_file app_group_file {
  filename        = "../infra/group_vars/app_servers"
  content         = templatefile("templates/app_group_vars.tpl",
    {
      region     = local.region
    })
  file_permission = 0644
}
