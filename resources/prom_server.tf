locals {
  prometheus_host    = formatlist("prometheus-%02d.utility.podspace.net ansible_host=%s", range(1), module.prom_server.public_ip)
}

module prom_server {
  source        = "./server"
  server_number = 1
  az_list       = local.az_list
  subnet_map    = local.subnet_map
  secgrps       = [local.secgrp_id, aws_security_group.prometheus_security_group.id]
  app           = "prom"
  server_count  = 1
  key_name      = local.key_name
}

resource aws_iam_access_key prom_access {
  user = "promsa"
}

resource aws_route53_record prometheus_internal {
  zone_id = aws_route53_zone.utility.zone_id
  name    = "prometheus.utility.podspace.net"
  type    = "A"
  ttl     = "300"
  records = module.prom_server.private_ip
}

output prometheus_public_ip {
  description = "Public ip of the prometheus server."
  value       = module.prom_server.public_ip
}

resource aws_route53_record prometheus_reverse {
  zone_id = aws_route53_zone.reverse.zone_id
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                              element(module.prom_server.private_ip, 0))))
  type    = "PTR"
  ttl     = "300"
  records = ["prometheus.utility.podspace.net"]
}