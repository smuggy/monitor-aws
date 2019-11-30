resource "aws_route53_zone" "utility" {
  name = "utility.podspace.net"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource "aws_route53_record" "prometheus_internal" {
  zone_id = aws_route53_zone.utility.zone_id
  count   = local.node_count
  name    = local.internal_prometheus[count.index]
  type    = "A"
  ttl     = "300"
  records = [lookup(aws_instance.prometheus_servers[count.index], "private_ip")]
}
