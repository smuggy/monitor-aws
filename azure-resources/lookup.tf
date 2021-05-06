locals {
  vn_name         = "scratch-central-us"
  rg_name         = "sb-scratch-resource-group"
  image_id        = data.azurerm_platform_image.ubuntu.id
  subscription_id = data.azurerm_subscription.current.subscription_id
}

data azurerm_subscription current {}

data azurerm_resource_group resource {
  name = local.rg_name
}

data azurerm_network_security_group vn_group {
  name                = "sandbox_net_sg"
  resource_group_name = local.rg_name
}

data azurerm_subnet subnet1 {
  name                 = "subnet1"
  virtual_network_name = local.vn_name
  resource_group_name  = local.rg_name
}

data azurerm_platform_image ubuntu {
  location  = "Central US"
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"
//  version   = "latest"
}
