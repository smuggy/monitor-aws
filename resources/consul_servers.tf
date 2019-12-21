module consul_servers {
  source        = "./server"
  server_number = 1
  az_list       = local.az_list
  subnet_map    = local.subnet_map
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
  volume_size   = 4
  server_count  = 3
}
