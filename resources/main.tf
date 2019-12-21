locals {
  node_count   = 1
  vpc_id       = data.aws_vpc.utility_vpc.id
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  ami_owner    = "099720109477"    # Canonical Group Limited
  key_name     = "utility-key"
#  ami_id       = data.aws_ami.ubuntu.id
  secgrp_name  = "utility_default_sg"
  region       = "us-east-2"

  az_one   = "${local.region}a"
  az_two   = "${local.region}b"
  az_three = "${local.region}c"

  internal_prometheus = "prometheus.utility.podspace.net"
  prometheus_host     = format("%s ansible_host=%s", local.internal_prometheus, module.prom_server.public_ip)

#  internal_consul     = formatlist("consul-%02d.utility.podspace.net", range(3))
  internal_consul     = ["consul-01.utility.podspace.net",
                        "consul-02.utility.podspace.net",
                        "consul-03.utility.podspace.net"]

  consul_private_ips  = [module.consul_server_one.private_ip,
                        module.consul_server_two.private_ip,
                        module.consul_server_three.private_ip]
  consul_public_ips   = [module.consul_server_one.public_ip,
                        module.consul_server_two.public_ip,
                        module.consul_server_three.public_ip]
  consul_hosts        = formatlist("%s ansible_host=%s", local.internal_consul, local.consul_public_ips)

}

data template_file all_hosts {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [module.prom_server]
  vars = {
    prometheus_host_group = local.prometheus_host
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
    root_ip = module.consul_server_two.private_ip
  }
  provisioner local-exec {
    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", local.internal_consul)}\n' > ../infra/group_vars/consul_servers"
  }
}

resource null_resource prom_groups_vars {
  triggers = {
    root_ip = module.consul_server_two.private_ip
  }
  provisioner local-exec {
    command = "echo 'consul_names:\n  - ${join("\n  - ", local.internal_consul)}\n' > ../infra/group_vars/prom_servers"
  }
}
