data template_file all_hosts {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [module.prom_server]
  vars = {
    prometheus_host_group = join("\n", local.prometheus_hosts)
    web_host_group        = ""
//    consul_host_group     = ""
    consul_host_group     = local.consul_host_group
//    web_host_group        = join("\n", local.ws_hosts)
    log_master_host_group = ""
    log_data_host_group   = ""
//    log_master_host_group = join("\n", local.log_master_hosts)
//    log_data_host_group   = join("\n", local.log_data_hosts)
  }
}

resource local_file host_file {
  filename        = "../infra/all_hosts"
  content         = data.template_file.all_hosts.rendered
  file_permission = 0644
}

data template_file prom_group_vars {
  template = file("templates/prom_groups_vars.tpl")
  vars = {
//    consuls = ""
    consuls    = local.internal_consul_string
    access_key = aws_iam_access_key.prom_access.id
    secret_key = aws_iam_access_key.prom_access.secret
  }
}

resource local_file prom_group_file {
  filename        = "../infra/group_vars/prom_servers"
  content         = data.template_file.prom_group_vars.rendered
  file_permission = 0644
}

data aws_route53_zone internal {
  name         = "podspace.local"
  private_zone = true
}

data aws_route53_zone reverse {
  name         = "32.10.in-addr.arpa"
  private_zone = true
}
