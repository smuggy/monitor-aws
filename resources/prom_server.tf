locals {
  prometheus_host    = formatlist("prometheus-%02d.internal.podspace.net ansible_host=%s",
                                  range(local.prom_count),
                                  aws_eip_association.prometheus_ip_assn.public_ip)
//                                  module.prom_server.public_ip)
  prom_count         = 1
  prom_instance_list = formatlist("  - %s: %s", module.prom_server.*.instance_id, "prometheus-00.internal.podspace.net")
  prom_instances     = format("\n%s", join("\n", local.prom_instance_list))
}

module prom_server {
  source        = "./server"
  az            = local.az_list[0]
  subnet        = lookup(local.subnet_map, local.az_list[0])
  sec_groups    = [local.secgrp_id, aws_security_group.prometheus_security_group.id]
  app           = "prom"
  count         = local.prom_count
  key_name      = local.key_name
  instance_type = "t3a.small"
}

resource aws_iam_access_key prom_access {
  user = "promsa"
}

//resource aws_route53_record prometheus_internal {
//  depends_on = [data.null_data_source.namezone]
//  count = "${data.null_data_source.namezone[0].outputs["value"] != "" && local.prom_count > 0 ? local.prom_count : 0}"
//  zone_id = data.null_data_source.namezone[0].outputs["value"]
//  name    = "prometheus"
//  type    = "A"
//  ttl     = "300"
//  records = module.prom_server.private_ip
//}

resource aws_route53_record prometheus_internal {
  type    = "A"
  ttl     = 300
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "prometheus.internal.podspace.net"
  records = [element(module.prom_server.*.private_ip, 0)]
}

//output prometheus_public_ip {
//  description = "Public ip of the prometheus server."
//  value       = module.prom_server.public_ip
//}

resource aws_route53_record prometheus_reverse {
  zone_id = data.aws_route53_zone.reverse.zone_id
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                              element(module.prom_server.*.private_ip, 0))))
  type    = "PTR"
  ttl     = "300"
  records = ["prometheus.internal.podspace.net"]
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

resource aws_security_group_rule prometheus_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
//  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 9090
  to_port           = 9090
}

resource aws_security_group_rule grafana_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 3000
  to_port           = 3000
}

resource aws_eip_association prometheus_ip_assn {
  instance_id        = element(module.prom_server.*.instance_id, 0)
  allocation_id      = data.aws_eip.prometheus_ip.id
}
