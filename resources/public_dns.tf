resource aws_route53_zone utility {
  name = "utility.podspace.net"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource aws_route53_record prometheus_internal {
  zone_id = aws_route53_zone.utility.zone_id
  name    = "prometheus.utility.podspace.net"
  type    = "A"
  ttl     = "300"
  records = module.prom_server.private_ip
}

resource aws_route53_record consul_internal {
  zone_id = aws_route53_zone.utility.zone_id
  count   = length(local.internal_consuls)
  name    = element(local.internal_consuls, count.index)
  type    = "A"
  ttl     = "300"
  records = [element(local.consul_private_ips, count.index)]
}

resource aws_route53_record consul_common {
  zone_id = aws_route53_zone.utility.zone_id
  name    = "consul.utility.podspace.net"
  type    = "A"
  ttl     = "300"
  records = local.consul_private_ips
}
