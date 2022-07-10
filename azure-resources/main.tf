locals {
  prometheus_host     = format("prometheus ansible_host=%s", module.prometheus_server.public_ip)
}

module rg {
  source = "git::https://github.com/smuggy/terraform-base//azure/management/resource_group?ref=main"
  name     = "utility"
  group    = "sandbox"
  location = "Central US"
}

module prometheus_server {
  source = "git::https://github.com/smuggy/tf-services//prometheus/azure?ref=main"

  app_rg_name = module.rg.rg_name
  ca_cert_key = file("../../vpcs/secrets/podspace_ca_key.pem")
  ca_cert_pem = file("../../vpcs/secrets/podspace_ca_cert.pem")
  network_rg_name        = data.azurerm_resource_group.net_resource.name
  network_rg_subnet_name = data.azurerm_subnet.subnet_1.name
  network_rg_vnet_name   = local.vn_name
  depends_on = [module.rg]
}

output prom_public {
  value = module.prometheus_server.public_ip
}

resource local_file nginx_external_key_file {
  file_permission = "0400"
  filename        = "../secrets/prometheus_public_key.pem"
  content         = module.prometheus_server.cert_key
}

resource local_file nginx_external_cert_file {
  file_permission = "0444"
  filename        = "../secrets/prometheus_public_cert.pem"
  content         = module.prometheus_server.cert_pem
}

resource local_file hosts {
  filename = "../infra/all_hosts"
  content = format("[consul_servers]\n\n[prom_servers]\n%s\n", local.prometheus_host)
}

resource local_file group_vars {
  filename = "../infra/group_vars/prom_servers"
  content  = format("provider: azure\nconsul_names:\n  - consul-1\nsubscription_id: ${local.subscription_id}\n")
}

resource local_file private_key_file {
  sensitive_content    = module.prometheus_server.ssh_private_key
  filename             = "../secrets/prometheus-key"
  file_permission      = 0400
  directory_permission = 0755
}

resource local_file public_key_file {
  content              = module.prometheus_server.ssh_public_key
  filename             = "../secrets/prometheus-key.pub"
  file_permission      = 0644
  directory_permission = 0755
}
