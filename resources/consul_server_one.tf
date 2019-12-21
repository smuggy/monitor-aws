module consul_server_one {
  source        = "./server"
  server_number = 1
  az            = "us-east-2a"
  subnet_id     = data.aws_subnet.utility_subnet_one.id
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
}
