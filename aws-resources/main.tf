resource local_file host_file {
  filename        = "../infra/all_hosts"
  content         = templatefile("${path.module}/templates/hosts.cfg",
    {
      prometheus_host_group = local.prometheus_host
      consul_host_group     = local.consul_host_group
      kafka_host_group      = local.kafka_host_group
      app_host_group        = local.app_host_group
    })
  file_permission = 0644
}

resource local_file prom_group_file {
  filename        = "../infra/group_vars/prom_servers"
  content         = templatefile("templates/prom_groups_vars.tpl",
    {
      consuls    = local.internal_consul_string
      region     = local.region
      access_key = aws_iam_access_key.prom_access.id
      secret_key = aws_iam_access_key.prom_access.secret
    })
  file_permission = 0644
}

resource local_file ssh_config {
  filename        = "../infra/ssh.cfg"
  content         = templatefile("templates/ssh.cfg",
    {
      bastion_ip   = module.prom_server.public_ip
      host_pattern = "10.20.*.*"
    })
  file_permission = 0644
}
