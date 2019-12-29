module prom_server {
  source        = "./server"
  server_number = 1
  az_list       = local.az_list
  subnet_map    = local.subnet_map
  secgrps       = [local.secgrp_id, aws_security_group.prometheus_security_group.id]
  app           = "prom"
  server_count  = 1
  key_name      = local.key_name
}

resource aws_iam_access_key prom_access {
  user = "promsa"
}
