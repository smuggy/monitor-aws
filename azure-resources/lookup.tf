locals {
  vn_name         = "scratch-central-us"
  rg_net_name     = "sandbox-network-rg"
  image_id        = data.azurerm_shared_image_version.ubuntu.id
  subscription_id = data.azurerm_subscription.current.subscription_id
}

data azurerm_subscription current {}

data azurerm_resource_group net_resource {
  name = local.rg_net_name
}

data azurerm_network_security_group vn_group {
  name                = "sandbox_net_sg"
  resource_group_name = local.rg_net_name
}

data azurerm_subnet subnet_1 {
  name                 = "scratch-subnet-1"
  virtual_network_name = local.vn_name
  resource_group_name  = local.rg_net_name
}

data azurerm_shared_image_version ubuntu {
  gallery_name        = "ImageGallery"
  image_name          = "UbuntuLinux"
  resource_group_name = local.rg_net_name
  name                = "2.0.0"
}
