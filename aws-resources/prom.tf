locals {
  prometheus_host = format("prometheus ansible_host=%s", module.prom_server.public_ip) # aws_instance.prom_server.public_ip)
}

module prom_server {
  source = "git::ssh://git@github.com/smuggy/tf-services.git//prometheus/aws?ref=main"
  //source = "git::https://github.com/smuggy/tf-services//prometheus/aws?ref=main"

  region            = "us-east-2"
  availability_zone = "us-east-2a"
  instance_type     = "t3a.small"
  server_group      = "1"
  ssh_key_name      = local.key_name
  vpc_id            = local.vpc_id
}


#---------------------
# resource aws_instance prom_server {
#   ami             = data.aws_ami.ubuntu.id
#   instance_type   = "t3.medium"
#   subnet_id       = local.public_subnet_map["us-east-2a"]
#   vpc_security_group_ids = [aws_security_group.prometheus_security_group.id, data.aws_security_group.default.id]
#   key_name        = local.key_name
#   tags = {
#     Name       = "prom-test-server"
#     name       = "promtest"
#     NodeExport = "true"
#   }
# }
#
# resource aws_route53_record internal {
#   zone_id = data.aws_route53_zone.internal.zone_id
#   name    = "prometheus.podspace.internal"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.prom_server.private_ip]
# }
#
# resource aws_route53_record external {
#   zone_id = data.aws_route53_zone.public.zone_id
#   name    = "prometheus.podspace.net"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.prom_server.public_ip]
# }

#-----------------------

resource aws_iam_access_key prom_access {
  user = "promsa"
}

output prom_public {
//  value = aws_instance.prom_server.public_ip
  value = module.prom_server.public_ip
}

module cert {
  source = "git::https://github.com/smuggy/terraform-base//tls/entity_certificate?ref=main"

  common_name     = "prometheus.${local.external_domain}"
  alternate_names = ["prometheus.${local.external_domain}","prometheus.${local.internal_domain}"]

//  alternate_ips   = [aws_instance.prom_server.public_ip]
  alternate_ips   = ["127.0.0.1", module.prom_server.public_ip, module.prom_server.private_ip]
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

#data aws_security_group prom_sg {
#  name = "prometheus_sg_1"
#}
#
#resource aws_security_group_rule prom_sg_consul {
#  security_group_id = data.aws_security_group.prom_sg.id
#  from_port         = 8300
#  to_port           = 8301
#  type              = "ingress"
#  protocol          = "tcp"
#  cidr_blocks       = ["10.0.0.0/8"]
#}
