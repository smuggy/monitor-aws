locals {
  utility_rg_name     = module.rg.rg_name
  utility_rg_location = module.rg.rg_location
  prometheus_host     = format("prometheus ansible_host=%s", module.prometheus_server.public_ip)
  internal_domain     = "podspace.cloud"
  external_domain     = "podspace.net"
}

module rg {
  source = "git::https://github.com/smuggy/terraform-base//azure/management/resource_group?ref=main"
  name     = "utility"
  group    = "sandbox"
  location = "Central US"
}

module prometheus_server {
  source = "git::https://github.com/smuggy/terraform-base//azure/compute/linux_vm?ref=main"

  app            = "prom"
  dns_rg_name    = local.rg_net_name
  subnet         = data.azurerm_subnet.subnet_1.id
  rg_name        = local.utility_rg_name
  rg_location    = local.utility_rg_location
  zone           = "1"
  ami_id         = data.azurerm_shared_image_version.ubuntu.id
  ssh_public_key = tls_private_key.key.public_key_openssh
  identity = [{id_type="UserAssigned", id=azurerm_user_assigned_identity.prom_identity.id}]
//  addl_tags = {
//    ServerGroup = "prometheus-server-1"
//    App         = "prometheus"
//    Name        = "prometheus"
//    NodeExport  = "true"
//  }
}

resource azurerm_network_interface_security_group_association nsg {
  network_interface_id      = module.prometheus_server.nic
  network_security_group_id = data.azurerm_network_security_group.vn_group.id
}

output prom_public {
  value = module.prometheus_server.public_ip
}

module nginx_cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "prometheus.${local.external_domain}"
  alternate_names = ["prometheus.${local.external_domain}"]

  alternate_ips   = [module.prometheus_server.public_ip]
  ca_private_key  = file("../../vpcs/secrets/podspace_ca_key.pem")
  ca_certificate  = file("../../vpcs/secrets/podspace_ca_cert.pem")
}

resource local_file nginx_external_key_file {
  file_permission = "0400"
  filename        = "../secrets/prometheus_public_key.pem"
  content         = module.nginx_cert.private_key
}

resource local_file nginx_external_cert_file {
  file_permission = "0444"
  filename        = "../secrets/prometheus_public_cert.pem"
  content         = module.nginx_cert.certificate_pem
}

resource azurerm_role_definition prom_role {
  name              = "prom-role"
  assignable_scopes = [module.rg.rg_id]
  scope             = module.rg.rg_id

  permissions {
    actions     = ["Microsoft.Compute/virtualMachines/read",
                   "Microsoft.Network/networkInterfaces/read"]
    not_actions = []
  }
}

resource azurerm_user_assigned_identity prom_identity {
  name                = "prom-access"
  resource_group_name = local.utility_rg_name
  location            = local.utility_rg_location
}

resource azurerm_role_assignment prom {
  principal_id         = azurerm_user_assigned_identity.prom_identity.principal_id
  scope                = module.rg.rg_id
  role_definition_name = azurerm_role_definition.prom_role.name
}

resource local_file hosts {
  filename = "../infra/all_hosts"
  content = format("[consul_servers]\n\n[prom_servers]\n%s\n", local.prometheus_host)
}

resource local_file group_vars {
  filename = "../infra/group_vars/prom_servers"
  content  = format("provider: azure\nconsul_names:\n  - consul-1\nsubscription_id: ${local.subscription_id}\n")
}

resource azurerm_private_dns_a_record prom {
  resource_group_name = local.rg_net_name
  zone_name           = local.internal_domain
  ttl                 = 3600
  name                = "prometheus"
  records             = [module.prometheus_server.private_ip]
}
