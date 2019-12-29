locals {
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  secgrp_name  = "utility_default_sg"

  prometheus_host    = formatlist("prometheus-%02d.utility.podspace.net ansible_host=%s", range(1), module.prom_server.public_ip)

  internal_consuls   = formatlist("consul-%02d.utility.podspace.net", range(3))
  consul_private_ips = module.consul_servers.private_ip
  consul_public_ips  = module.consul_servers.public_ip
  consul_hosts       = formatlist("%s ansible_host=%s", local.internal_consuls, local.consul_public_ips)
  internal_consul_string = join("\n  - ", local.internal_consuls)
}

data template_file all_hosts {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [module.prom_server]
  vars = {
    prometheus_host_group = join("\n", local.prometheus_host)
    consul_host_group     = join("\n", local.consul_hosts)
  }
}

resource local_file host_file {
  filename        = "../infra/all_hosts"
  content         = data.template_file.all_hosts.rendered
  file_permission = 0644
}

resource null_resource consul_groups_vars {
  triggers = {
    root_ip = element(module.consul_servers.private_ip, 0)
  }
  provisioner local-exec {
    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", local.internal_consuls)}\n' > ../infra/group_vars/consul_servers"
  }
}

#resource null_resource prom_groups_vars {
#  triggers = {
#    root_ip = element(module.consul_servers.private_ip, 0)
#  }
#  provisioner local-exec {
#    command = "echo 'consul_names:\n  - ${join("\n  - ", local.internal_consuls)}\n' > ../infra/group_vars/prom_servers"
#  }
#}

data template_file prom_group_vars {
  template = file("templates/prom_groups_vars.tpl")
  vars = {
    consuls = local.internal_consul_string
    access_key = aws_iam_access_key.prom_access.id
    secret_key = aws_iam_access_key.prom_access.secret
  }
}

resource local_file prom_group_file {
  filename        = "../infra/group_vars/prom_servers"
  content         = data.template_file.prom_group_vars.rendered
  file_permission = 0644
}
