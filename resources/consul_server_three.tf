module consul_server_three {
  source        = "./server"
  server_number = 3
  az            = "us-east-2c"
  subnet_id     = data.aws_subnet.utility_subnet_three.id
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
}
