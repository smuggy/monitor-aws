locals {
  prometheus_host = format("prometheus ansible_host=%s", azurerm_linux_virtual_machine.prometheus.public_ip_address)
  internal_domain = "podspace.cloud"
  external_domain = "podspace.net"
  ip_portion = join(".", reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                    azurerm_linux_virtual_machine.prometheus.private_ip_address)))
}

resource azurerm_public_ip prometheus {
  name                = "prometheus-public-ip"
  resource_group_name = local.rg_name
  location            = data.azurerm_resource_group.resource.location
  allocation_method   = "Static"
  ip_version          = "IPv4"
  zones               = ["1"]
  sku                 = "Standard"

  tags = {
    environment = "sandbox"
  }
}

resource azurerm_network_interface prometheus_nic {
  name                      = "prometheus-nic"
  location                  = data.azurerm_resource_group.resource.location
  resource_group_name       = local.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.prometheus.id
  }
}

resource azurerm_network_interface_security_group_association nsg {
  network_interface_id      = azurerm_network_interface.prometheus_nic.id
  network_security_group_id = data.azurerm_network_security_group.vn_group.id
}

resource azurerm_linux_virtual_machine prometheus {
  name                = "prometheus"
  resource_group_name = local.rg_name
  location            = data.azurerm_resource_group.resource.location
  size                = "Standard_B1s"
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.prometheus_nic.id
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.prom_identity.id]
  }

//  source_image_id = local.image_id
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  zone        = "1"

  tags = {
    ServerGroup = "prometheus-server-1"
    App         = "prometheus"
    Name        = "prometheus"
    NodeExport  = "true"
  }
}

output public_ip {
  value = azurerm_linux_virtual_machine.prometheus.public_ip_address
}

output prom_public {
  value = azurerm_linux_virtual_machine.prometheus.public_ip_address
}

module nginx_cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "prometheus.${local.external_domain}"
  alternate_names = ["prometheus.${local.external_domain}"]

  alternate_ips   = [azurerm_linux_virtual_machine.prometheus.public_ip_address]
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
  assignable_scopes = [data.azurerm_resource_group.resource.id]
  scope             = data.azurerm_resource_group.resource.id

  permissions {
    actions     = ["Microsoft.Compute/virtualMachines/read",
                   "Microsoft.Network/networkInterfaces/read"]
    not_actions = []
  }
}

resource azurerm_user_assigned_identity prom_identity {
  name                = "prom-access"
  resource_group_name = data.azurerm_resource_group.resource.name
  location            = data.azurerm_resource_group.resource.location
}

resource azurerm_role_assignment prom {
  principal_id         = azurerm_user_assigned_identity.prom_identity.principal_id
  scope                = data.azurerm_resource_group.resource.id
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
  resource_group_name = data.azurerm_resource_group.resource.name
  zone_name           = local.internal_domain
  ttl                 = 3600
  name                = "prometheus"
  records             = [azurerm_linux_virtual_machine.prometheus.private_ip_address]
}

resource azurerm_private_dns_ptr_record reverse {
  resource_group_name = data.azurerm_resource_group.resource.name
  zone_name           = "48.10.in-addr.arpa"
  ttl                 = 3600
  name                = local.ip_portion
  records             = ["prometheus.${local.internal_domain}"]
}
