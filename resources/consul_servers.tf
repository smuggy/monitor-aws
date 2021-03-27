locals {
  consul_server_count    = 3
  internal_consuls       = formatlist("consul-%02d", range(length(local.subnet_map)))
  consul_hosts           = formatlist("%s ansible_host=%s", local.internal_consuls, module.consul_servers.*.public_ip)
  internal_consul_string = join("\n  - ", local.internal_consuls)
  consul_host_group      = join("\n", local.consul_hosts)
}

module consul_servers {
  source = "git::https://github.com/smuggy/terraform-base//aws/compute/instance?ref=main"

  count         = local.consul_server_count
  az            = element(local.az_list, count.index)
  subnet        = lookup(local.subnet_map, element(local.az_list, count.index))
  sec_groups    = [local.sec_group_id, aws_security_group.consul_security_group.id]
  app           = "cnsl"
  volume_size   = 4
  key_name      = local.key_name
  region        = local.region

  name_zone_id    = data.aws_route53_zone.internal.zone_id
  reverse_zone_id = data.aws_route53_zone.reverse.zone_id
}

resource aws_route53_record consul_internal {
  zone_id = data.aws_route53_zone.internal.zone_id
  count   = length(local.internal_consuls)
  name    = element(local.internal_consuls, count.index)
  type    = "A"
  ttl     = "300"
  records = [element(module.consul_servers.*.private_ip, count.index)]
}

resource aws_route53_record consul_common {
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "consul"
  type    = "A"
  ttl     = "300"
  records = module.consul_servers.*.private_ip
}
//
output consul_public_ips {
  description = "Public ips for consul servers"
  value       = module.consul_servers.*.public_ip
}

resource aws_security_group consul_security_group {
  name   = "consul_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule consul_ui_tcp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 8500
  to_port           = 8501
}

resource aws_security_group_rule consul_dns_tcp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 8600
  to_port           = 8600
}

resource aws_security_group_rule consul_ne_tcp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 9100
  to_port           = 9100
}

resource aws_security_group_rule consul_dns_udp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 8600
  to_port           = 8600
}

resource aws_security_group_rule consul_self_all {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  self              = true
}

resource null_resource consul_groups_vars {
  triggers = {
    root_ip = join(",", sort(module.consul_servers.*.private_ip))
  }
  provisioner local-exec {
    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", local.internal_consuls)}\n' > ../infra/group_vars/consul_servers"
  }
}

module consul_certs {
  source = "./cert"
  count  = local.consul_server_count

  ca_cert_pem = file("../../vpcs/secrets/podspace_ca.pem")
  ca_key_pem  = file("../../vpcs/secrets/ca_key.pem")
  alt_name    = "consul.internal.podspace.net"
  ip_address  = element(module.consul_servers.*.private_ip, count.index)
  common_name = element(local.internal_consuls, count.index)
}

resource random_id gossip_key {
  byte_length = 32
}

resource local_file gossip_key {
  filename = "../secrets/gossip_key"
  content = random_id.gossip_key.b64_std
}
