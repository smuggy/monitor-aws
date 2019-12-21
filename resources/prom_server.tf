module prom_server {
  source        = "./server"
  server_number = 1
  az            = "us-east-2b"
  subnet_id     = data.aws_subnet.utility_subnet_two.id
  secgrps       = [local.secgrp_id, aws_security_group.prometheus_security_group.id]
  app           = "prom"
}
