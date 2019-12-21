module consul_server_two {
  source        = "./server"
  server_number = 2
  az            = "us-east-2b"
  subnet_id     = data.aws_subnet.utility_subnet_two.id
  secgrps       = [local.secgrp_id, aws_security_group.consul_security_group.id]
  app           = "consul"
}
