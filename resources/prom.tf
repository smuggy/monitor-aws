locals {
  prometheus_host = format("prometheus ansible_host=%s", module.prom_server.public_ip)
}

module prom_server {
  source = "git::https://github.com/smuggy/tf-services//prometheus?ref=main"

  region            = "us-east-2"
  availability_zone = "us-east-2a"
  instance_type     = "t3a.medium"
  server_group      = "1"
  ssh_key_name      = local.key_name
  vpc_id            = local.vpc_id
}

resource aws_iam_access_key prom_access {
  user = "promsa"
}

output prom_public {
  value = module.prom_server.public_ip
}
