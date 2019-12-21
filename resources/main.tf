locals {
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  secgrp_name  = "utility_default_sg"

  prometheus_host    = formatlist("prometheus-%02d.utility.podspace.net ansible_host=%s", range(1), module.prom_server.public_ip)

  internal_consuls   = formatlist("consul-%02d.utility.podspace.net", range(3))
  consul_private_ips = module.consul_servers.private_ip
  consul_public_ips  = module.consul_servers.public_ip
  consul_hosts       = formatlist("%s ansible_host=%s", local.internal_consuls, local.consul_public_ips)
}

data template_file all_hosts {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [module.prom_server]
  vars = {
    prometheus_host_group = join("\n", local.prometheus_host)
    consul_host_group     = join("\n", local.consul_hosts)
  }
}

resource null_resource hosts {
  triggers = {
    template_rendered = data.template_file.all_hosts.rendered
  }
  provisioner local-exec {
    command = "echo '${data.template_file.all_hosts.rendered}' > ../infra/all_hosts"
  }
}

resource null_resource consul_groups_vars {
  triggers = {
    root_ip = element(module.consul_servers.private_ip, 0)
  }
  provisioner local-exec {
    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", local.internal_consuls)}\n' > ../infra/group_vars/consul_servers"
  }
}

resource null_resource prom_groups_vars {
  triggers = {
    root_ip = element(module.consul_servers.private_ip, 0)
  }
  provisioner local-exec {
    command = "echo 'consul_names:\n  - ${join("\n  - ", local.internal_consuls)}\n' > ../infra/group_vars/prom_servers"
  }
}
