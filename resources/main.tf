data template_file all_hosts {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [module.prom_server]
  vars = {
    prometheus_host_group = join("\n", local.prometheus_host)
    consul_host_group     = ""
//    consul_host_group     = join("\n", local.consul_hosts)
  }
}

resource local_file host_file {
  filename        = "../infra/all_hosts"
  content         = data.template_file.all_hosts.rendered
  file_permission = 0644
}

//resource null_resource consul_groups_vars {
//  triggers = {
//    root_ip = element(module.consul_servers.private_ip, 0)
//  }
//  provisioner local-exec {
//    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", local.internal_consuls)}\n' > ../infra/group_vars/consul_servers"
//  }
//}
//
data template_file prom_group_vars {
  template = file("templates/prom_groups_vars.tpl")
  vars = {
    consuls = ""
//    consuls = local.internal_consul_string
    access_key = aws_iam_access_key.prom_access.id
    secret_key = aws_iam_access_key.prom_access.secret
  }
}

resource local_file prom_group_file {
  filename        = "../infra/group_vars/prom_servers"
  content         = data.template_file.prom_group_vars.rendered
  file_permission = 0644
}

resource aws_route53_zone utility {
  name = "utility.podspace.net"
  vpc {
    vpc_id = local.vpc_id
  }
}

resource aws_route53_zone reverse {
  name = "20.10.in-addr.arpa"
  vpc {
    vpc_id = local.vpc_id
  }
}
