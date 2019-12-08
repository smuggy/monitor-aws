resource "aws_route53_zone" "utility" {
  name = "utility.podspace.net"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource "aws_route53_record" "prometheus_internal" {
  zone_id = aws_route53_zone.utility.zone_id
  name    = local.internal_prometheus
  type    = "A"
  ttl     = "300"
  records = [aws_instance.prometheus_server.private_ip]
}

resource "aws_route53_record" "consul_internal" {
  zone_id = aws_route53_zone.utility.zone_id
  count   = 3
  name    = element(local.internal_consul, count.index)
  type    = "A"
  ttl     = "300"
  records = local.consul_private_ips
}

resource "aws_route53_record" "consul_common" {
  zone_id = aws_route53_zone.utility.zone_id
  name    = "consul.utility.podspace.net"
  type    = "A"
  ttl     = "300"
  records = local.consul_private_ips
}
