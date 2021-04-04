locals {
  prom_count         = 1
  prometheus_hosts = formatlist("%s ansible_host=%s",
                                "prometheus",
                                aws_eip_association.prometheus_ip_assn.public_ip)
  external_domain = "podspace.net"
  internal_domain = "podspace.local"
}

module prom_server {
  source = "git::https://github.com/smuggy/terraform-base//aws/compute/instance?ref=main"

  region        = local.region
  az            = local.az_list[0]
  subnet        = lookup(local.public_subnet_map, local.az_list[0])
  sec_groups    = [local.sec_group_id, aws_security_group.prometheus_security_group.id]
  app           = "prom"
  key_name      = local.key_name
  instance_type = "t3a.small"

  name_zone_id    = data.aws_route53_zone.internal.zone_id
  reverse_zone_id = data.aws_route53_zone.reverse.zone_id
}

resource aws_iam_access_key prom_access {
  user = "promsa"
}

resource aws_route53_record prometheus_internal {
  type    = "A"
  ttl     = 300
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "prometheus.${local.internal_domain}"
  records = [module.prom_server.private_ip]
}

resource aws_security_group prometheus_security_group {
  name   = "prometheus_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule prometheus_http {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
}

resource aws_security_group_rule prometheus_https {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}

resource aws_security_group_rule prometheus_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr]
  from_port         = 9090
  to_port           = 9095
}

resource aws_security_group_rule grafana_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr]
  from_port         = 3000
  to_port           = 3000
}

resource aws_eip_association prometheus_ip_assn {
  instance_id        = module.prom_server.instance_id
  allocation_id      = data.aws_eip.prometheus_ip.id
}
