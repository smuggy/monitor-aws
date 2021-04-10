module nginx_cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "prometheus.${local.external_domain}"
  alternate_names = ["prometheus.${local.external_domain}"]

  alternate_ips   = [module.prom_server.public_ip]
  ca_private_key  = file("../../vpcs/secrets/podspace_ca_key.pem")
  ca_certificate  = file("../../vpcs/secrets/podspace_ca_cert.pem")
}

resource local_file nginx_external_key_file {
  file_permission = "0400"
  filename        = "../secrets/prometheus_public_key.pem"
  content         = module.nginx_cert.private_key
}

resource local_file nginx_external_cert_file {
  file_permission = "0444"
  filename        = "../secrets/prometheus_public_cert.pem"
  content         = module.nginx_cert.certificate_pem
}

//module consul_certs {
//  source = "./cert"
//  count  = local.consul_server_count
//
//  ca_cert_pem = file("../../vpcs/secrets/local_ca_cert.pem")
//  ca_key_pem  = file("../../vpcs/secrets/local_ca_key.pem")
//  alt_name    = "consul.${local.internal_domain}"
//  ip_address  = element(module.consul_servers.*.private_ip, count.index)
//  common_name = element(local.internal_consuls, count.index)
//}

module consul_certs {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"
  count  = local.consul_server_count

  common_name     = element(local.internal_consuls, count.index)
  alternate_names = ["consul.${local.internal_domain}", element(module.consul_servers.*.instance_name, count.index)]
  alternate_ips   = [element(module.consul_servers.*.private_ip, count.index)]
  ca_private_key  = file("../../vpcs/secrets/podspace_ca_key.pem")
  ca_certificate  = file("../../vpcs/secrets/podspace_ca_cert.pem")
}

resource local_file key {
  count = local.consul_server_count

  filename          = "../secrets/${element(local.internal_consuls, count.index)}-key.pem"
  sensitive_content = element(module.consul_certs.*.private_key, count.index)
  file_permission   = 0440
}

resource local_file cert {
  count = local.consul_server_count

  filename        = "../secrets/${element(local.internal_consuls, count.index)}-cert.pem"
  content         = element(module.consul_certs.*.certificate_pem, count.index)
  file_permission = 0444
}
