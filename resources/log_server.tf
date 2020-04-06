locals {
  log_count       = 1
  internal_log    = formatlist("ls-%02d.utility.podspace.net", range(local.log_count))
  log_private_ips = module.log_servers.private_ip
  log_public_ips  = module.log_servers.public_ip
  log_hosts       = formatlist("%s ansible_host=%s", local.internal_log, local.log_public_ips)
}

module log_servers {
  source        = "./server"
  server_number = 1
  az_list       = local.az_list
  subnet_map    = local.subnet_map
  secgrps       = [local.secgrp_id, aws_security_group.log_security_group.id]
  app           = "log"
  volume_size   = 4
  server_count  = local.log_count
  key_name      = local.key_name
  instance_type = "t3a.large"
}

resource aws_security_group log_security_group {
  name   = "ls_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule log_es_tcp {
  security_group_id = aws_security_group.log_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9200
  to_port           = 9300
}

resource aws_security_group_rule log_es_http {
  security_group_id = aws_security_group.log_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
}

output log_public_ips {
  description = "Public ips for log servers"
  value       = local.log_public_ips
}
