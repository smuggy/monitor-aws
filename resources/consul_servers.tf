module consul_server_one {
  source        = "./server"
  server_number = 1
  az            = element(local.az_list, 0)
  subnet_id     = local.subnet_map[element(local.az_list, 0)]
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
  volume_size   = 4
}

module consul_server_two {
  source        = "./server"
  server_number = 2
  az            = element(local.az_list, 1)
  subnet_id     = local.subnet_map[element(local.az_list, 1)]
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
  volume_size   = 4
}

module consul_server_three {
  source        = "./server"
  server_number = 3
  az            = element(local.az_list, 2)
  subnet_id     = local.subnet_map[element(local.az_list, 2)]
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
  volume_size   = 4
}
