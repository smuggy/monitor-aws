data template_file all_hosts {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [module.prom_server]
  vars = {
    prometheus_host_group = local.prometheus_host
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

data template_file ssh_config {
  template = file("templates/ssh.cfg")
  vars = {
    bastion_ip   = module.prom_server.public_ip
    host_pattern = "10.32.*.*"
  }
}

resource local_file ssh_config {
  filename        = "../infra/ssh.cfg"
  content         = data.template_file.ssh_config.rendered
  file_permission = 0644
}
