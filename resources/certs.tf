module nginx_cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "prometheus.${local.external_domain}"
  alternate_names = ["prometheus.${local.external_domain}"]

  alternate_ips   = [data.aws_eip.prometheus_ip.public_ip]
  ca_private_key  = file("../../vpcs/secrets/podspace_ca_key.pem")
  ca_certificate  = file("../../vpcs/secrets/podspace_ca_cert.pem")
}

resource local_file nginx_external_key_file {
  file_permission = "0400"
  filename        = "../secrets/prometheus_public_key.pem"
  content         = module.nginx_cert.private_key
}

resource local_file vault_node_cert_file {
  file_permission = "0444"
  filename        = "../secrets/prometheus_public_cert.pem"
  content         = module.nginx_cert.certificate_pem
}
