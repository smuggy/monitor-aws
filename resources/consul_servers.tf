locals {
  consul_server_count    = module.consul_cluster.cluster_server_count
  consul_hosts           = formatlist("%s ansible_host=%s", module.consul_cluster.server_names, module.consul_cluster.private_ips)
  internal_consul_string = join("\n  - ", module.consul_cluster.server_names)
  consul_host_group      = join("\n", local.consul_hosts)
}

module consul_cluster {
  source = "git::https://github.com/smuggy/tf-services//consul?ref=main"

  cluster_size  = "medium"
  instance_type = "t3a.micro"
  server_group  = "1"
  vpc_id        = local.vpc_id
  ssh_key_name  = local.key_name
  region        = local.region
}

resource null_resource consul_groups_vars {
  triggers = {
    root_ip = join(",", sort(module.consul_cluster.private_ips))
  }
  provisioner local-exec {
    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", module.consul_cluster.server_names)}\nregion: ${local.region}' > ../infra/group_vars/consul_servers"
  }
}

resource null_resource consul_host_vars {
  count = local.consul_server_count
  triggers = {
    root_ip = module.consul_cluster.private_ips[count.index]
  }
  provisioner local-exec {
    command = "echo 'private_host: true\n' > ../infra/host_vars/${module.consul_cluster.server_names[count.index]}"
  }
}

resource random_id gossip_key {
  byte_length = 32
}

resource local_file gossip_key {
  filename = "../secrets/gossip_key"
  content  = random_id.gossip_key.b64_std
}

module consul_certs {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"
  count  = local.consul_server_count

  common_name     = element(module.consul_cluster.server_names, count.index)
  alternate_names = ["consul.${local.internal_domain}",
                     "${element(module.consul_cluster.instance_names, count.index)}.${local.internal_domain}",
                     "${element(module.consul_cluster.server_names, count.index)}.${local.internal_domain}"]
  alternate_ips   = [element(module.consul_cluster.private_ips, count.index)]
  ca_private_key  = file("../../vpcs/secrets/local_ca_key.pem")
  ca_certificate  = file("../../vpcs/secrets/local_ca_cert.pem")
}

resource local_file key {
  count = local.consul_server_count

  filename          = "../secrets/${element(module.consul_cluster.server_names, count.index)}-key.pem"
  sensitive_content = element(module.consul_certs.*.private_key, count.index)
  file_permission   = 0440
}

resource local_file cert {
  count = local.consul_server_count

  filename        = "../secrets/${element(module.consul_cluster.server_names, count.index)}-cert.pem"
  content         = element(module.consul_certs.*.certificate_pem, count.index)
  file_permission = 0444
}

output consul_private_ips {
  description = "Private ips for consul servers"
  value       = module.consul_cluster.private_ips
}
