locals {
  prometheus_host = format("prometheus ansible_host=%s", module.prom_server.public_ip)
}

module prom_server {
  source = "git::https://github.com/smuggy/tf-services//prometheus/aws?ref=main"

  region            = "us-east-2"
  availability_zone = "us-east-2a"
  instance_type     = "t3a.small"
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

module cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "prometheus.${local.external_domain}"
  alternate_names = ["prometheus.${local.external_domain}","prometheus.${local.internal_domain}"]

  alternate_ips   = [module.prom_server.public_ip]
  ca_private_key  = file("../../vpcs/secrets/podspace_ca_key.pem")
  ca_certificate  = file("../../vpcs/secrets/podspace_ca_cert.pem")
}

resource local_file nginx_external_key_file {
  file_permission = "0400"
  filename        = "../secrets/prometheus_public_key.pem"
  content         = module.cert.private_key
}

resource local_file nginx_external_cert_file {
  file_permission = "0444"
  filename        = "../secrets/prometheus_public_cert.pem"
  content         = module.cert.certificate_pem
}
