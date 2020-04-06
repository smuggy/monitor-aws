//locals {
//  internal_consuls   = formatlist("consul-%02d.utility.podspace.net", range(3))
//  consul_private_ips = module.consul_servers.private_ip
//  consul_public_ips  = module.consul_servers.public_ip
//  consul_hosts       = formatlist("%s ansible_host=%s", local.internal_consuls, local.consul_public_ips)
//  internal_consul_string = join("\n  - ", local.internal_consuls)
//}
//
//module consul_servers {
//  source        = "./server"
//  server_number = 1
//  az_list       = local.az_list
//  subnet_map    = local.subnet_map
//  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
//  app           = "consul"
//  volume_size   = 4
//  server_count  = 3
//  key_name      = local.key_name
//}
//
//resource aws_route53_record consul_internal {
//  zone_id = aws_route53_zone.utility.zone_id
//  count   = length(local.internal_consuls)
//  name    = element(local.internal_consuls, count.index)
//  type    = "A"
//  ttl     = "300"
//  records = [element(local.consul_private_ips, count.index)]
//}
//
//resource aws_route53_record consul_common {
//  zone_id = aws_route53_zone.utility.zone_id
//  name    = "consul.utility.podspace.net"
//  type    = "A"
//  ttl     = "300"
//  records = local.consul_private_ips
//}

//output consul_public_ips {
//  description = "Public ips for consul servers"
//  value       = local.consul_public_ips
//}

//resource aws_security_group consul_security_group {
//  name   = "consul_sg"
//  vpc_id = local.vpc_id
//}

//resource aws_security_group_rule consul_ui_tcp {
//  security_group_id = aws_security_group.consul_security_group.id
//  type              = "ingress"
//  protocol          = "tcp"
//  cidr_blocks       = ["10.20.0.0/16"]
//  from_port         = 8500
//  to_port           = 8500
//}
//
//resource aws_security_group_rule consul_dns_tcp {
//  security_group_id = aws_security_group.consul_security_group.id
//  type              = "ingress"
//  protocol          = "tcp"
//  cidr_blocks       = ["10.20.0.0/16"]
//  from_port         = 8600
//  to_port           = 8600
//}
//
//resource aws_security_group_rule consul_ne_tcp {
//  security_group_id = aws_security_group.consul_security_group.id
//  type              = "ingress"
//  protocol          = "tcp"
//  cidr_blocks       = ["10.20.0.0/16"]
//  from_port         = 9100
//  to_port           = 9100
//}

//resource aws_security_group_rule consul_dns_udp {
//  security_group_id = aws_security_group.consul_security_group.id
//  type              = "ingress"
//  protocol          = "udp"
//  cidr_blocks       = ["10.20.0.0/16"]
//  from_port         = 8600
//  to_port           = 8600
//}
//
//resource aws_security_group_rule consul_self_all {
//  security_group_id = aws_security_group.consul_security_group.id
//  type              = "ingress"
//  protocol          = "all"
//  from_port         = 0
//  to_port           = 65000
//  self              = true
//}
