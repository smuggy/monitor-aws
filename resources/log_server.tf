locals {
  log_master_count       = 1
  log_data_count         = 2
  internal_master_log    = formatlist("elk-master-%02d.internal.podspace.net", range(local.log_master_count))
  log_master_private_ips = module.master_servers.private_ip
  log_master_public_ips  = module.master_servers.public_ip
  log_master_hosts       = formatlist("%s ansible_host=%s", local.internal_master_log, local.log_master_public_ips)
  log_master_nodes       = formatlist("master-%d", range(local.log_master_count))

  internal_data_log      = formatlist("elk-data-%02d.internal.podspace.net", range(local.log_data_count))
  log_data_private_ips   = module.data_servers.private_ip
  log_data_public_ips    = module.data_servers.public_ip
  log_data_hosts         = formatlist("%s ansible_host=%s", local.internal_data_log, local.log_data_public_ips)
}

module master_servers {
  source        = "./server"
  az_list       = local.az_list
  subnet_map    = local.subnet_map
  secgrps       = [local.secgrp_id, aws_security_group.log_security_group.id]
  app           = "elk-master"
  volume_size   = 4
  server_count  = local.log_master_count
  key_name      = local.key_name
  instance_type = "t3a.medium"
}

module data_servers {
  source        = "./server"
  az_list       = local.az_list
  subnet_map    = local.subnet_map
  secgrps       = [local.secgrp_id, aws_security_group.log_security_group.id]
  app           = "elk-data"
  volume_size   = 10
  server_count  = local.log_data_count
  key_name      = local.key_name
  instance_type = "t3a.medium"
}

resource aws_security_group log_security_group {
  name   = "elk_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule log_es_tcp {
  security_group_id = aws_security_group.log_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 9200
  to_port           = 9300
}

resource aws_security_group_rule log_es_ne {
  security_group_id = aws_security_group.log_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 9100
  to_port           = 9100
}

resource aws_security_group_rule log_es_http {
  security_group_id = aws_security_group.log_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 5601
  to_port           = 5601
}

resource aws_security_group_rule log_self {
  security_group_id = aws_security_group.log_security_group.id
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  type              = "ingress"
  self              = true
}

//resource aws_security_group_rule log_es_http {
//  security_group_id = aws_security_group.log_security_group.id
//  type              = "ingress"
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//  from_port         = 80
//  to_port           = 80
//}

output log_public_ips {
  description = "Public ips for log servers"
  value       = local.log_master_public_ips
}

resource aws_route53_record kibana_internal {
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "kibana.internal.podspace.net"
  type    = "A"
  ttl     = "300"
  records = module.master_servers.private_ip
}

resource aws_route53_record elasticsearch_internal {
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "elasticsearch.internal.podspace.net"
  type    = "CNAME"
  ttl     = "300"
  records = ["kibana.internal.podspace.net"]
}

resource aws_route53_record kibana_reverse {
  zone_id = data.aws_route53_zone.reverse.zone_id
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
  element(module.master_servers.private_ip, 0))))
  type    = "PTR"
  ttl     = "300"
  records = ["kibana.internal.podspace.net"]
}

resource aws_route53_record elk_data_internal {
  count   = local.log_data_count
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = local.internal_data_log[count.index]
  type    = "A"
  ttl     = "300"
  records = module.data_servers.private_ip
}

resource aws_route53_record elk_data_reverse {
  count   = local.log_data_count
  zone_id = data.aws_route53_zone.reverse.zone_id
  name    = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                  element(module.data_servers.private_ip, count.index))))
  records = [local.internal_data_log[count.index]]
  type    = "PTR"
  ttl     = "300"
}

data template_file data_hostvar {
  count    = local.log_data_count
  template = file("templates/hostvars.tpl")
  vars     = {
    node_name    = "data-${count.index}"
    master_ips   = join(",", local.log_master_private_ips)
    master_names = join(",", local.log_master_nodes)
  }
}

data template_file master_hostvar {
  count    = local.log_master_count
  template = file("templates/hostvars.tpl")
  vars     = {
    node_name = "master-${count.index}"
    master_ips   = join(",", local.log_master_private_ips)
    master_names = join(",", local.log_master_nodes)
  }
}

resource local_file data_hostvar_file {
  count    = local.log_data_count
  filename = "../infra/host_vars/${local.internal_data_log[count.index]}"
  content  = data.template_file.data_hostvar.*.rendered[count.index]
}

resource local_file master_hostvar_file {
  count    = local.log_master_count
  filename = "../infra/host_vars/${local.internal_master_log[count.index]}"
  content  = data.template_file.master_hostvar.*.rendered[count.index]
}
