#data template_file all_hosts {
#  template = file("${path.module}/templates/hosts.cfg")
#  depends_on = [module.prom_server]
#  vars = {
#    prometheus_host_group = local.prometheus_host
#    consul_host_group     = local.consul_host_group
#  }
#}

resource local_file host_file {
  filename        = "../infra/all_hosts"
  content         = templatefile("${path.module}/templates/hosts.cfg",
    {
      prometheus_host_group = local.prometheus_host
      consul_host_group     = "" # local.consul_host_group
      kafka_host_group      = local.kafka_host_group
    })
#  content         = data.template_file.all_hosts.rendered
  file_permission = 0644
}

#data template_file prom_group_vars {
#  template = file("templates/prom_groups_vars.tpl")
#  vars = {
#    consuls    = local.internal_consul_string
#    region     = local.region
##    consuls    = ""
#    access_key = aws_iam_access_key.prom_access.id
#    secret_key = aws_iam_access_key.prom_access.secret
#  }
#}
#
resource local_file prom_group_file {
  filename        = "../infra/group_vars/prom_servers"
  content         = templatefile("templates/prom_groups_vars.tpl",
    {
      consuls    = "" #local.internal_consul_string
      region     = local.region
      access_key = aws_iam_access_key.prom_access.id
      secret_key = aws_iam_access_key.prom_access.secret
    })
  file_permission = 0644
}

#data template_file ssh_config {
#  template = file("templates/ssh.cfg")
#  vars = {
#    bastion_ip   = module.prom_server.public_ip
#    host_pattern = "10.32.*.*"
#  }
#}

resource local_file ssh_config {
  filename        = "../infra/ssh.cfg"
  content         = templatefile("templates/ssh.cfg",
    {
      bastion_ip   = module.prom_server.public_ip
      host_pattern = "10.20.*.*"
    })
#  content         = data.template_file.ssh_config.rendered
  file_permission = 0644
}
