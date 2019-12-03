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
  name    = local.internal_consul
  type    = "A"
  ttl     = "300"
  records = [aws_instance.consul_server.private_ip]
}
