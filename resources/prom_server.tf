module prom_server {
  source        = "./server"
  server_number = 1
  az            = element(local.az_list, 1)
  subnet_id     = local.subnet_map[element(local.az_list, 1)]
  secgrps       = [local.secgrp_id, aws_security_group.prometheus_security_group.id]
  app           = "prom"
}
