resource local_file host_file {
  filename        = "../infra/all_hosts"
  content         = templatefile("${path.module}/templates/hosts.cfg",
    {
      prometheus_host_group = local.prometheus_host
      consul_host_group     = local.consul_host_group // ""
      kafka_host_group      = module.kafka.kafka_host_group // ""
      app_host_group        = "" // local.app_host_group // ""
      zookeeper_host_group  = "" // module.zookeeper.zookeeper_host_group // ""
    })
  file_permission = 0644
}

resource local_file prom_group_file {
  filename        = "../infra/group_vars/prom_servers"
  content         = templatefile("templates/prom_groups_vars.tpl",
    {
      consuls        = local.internal_consul_string
      region         = local.region
      access_key     = aws_iam_access_key.prom_access.id
      secret_key     = aws_iam_access_key.prom_access.secret
      consul_enabled = local.internal_consul_string == "" ? "false" : "true"
    })
  file_permission = 0644
}

resource local_file ssh_config {
  filename        = "../infra/ssh.cfg"
  content         = templatefile("templates/ssh.cfg",
    {
      bastion_ip   = module.prom_server.public_ip
      host_pattern = "10.20.*.*"
    })
  file_permission = 0644
}

# resource aws_instance test_instance {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t3.large"
#   subnet_id     = local.public_subnet_map["us-east-2a"]
#   key_name      = local.key_name
#   vpc_security_group_ids = [data.aws_security_group.default.id, aws_security_group.prometheus_security_group.id]
#   tags = {
#     Name       = "kafka-test-server"
#     name       = "kafka-test"
#     NodeExport = "true"
#   }
# }
#
# #--------------------
# resource aws_route53_record kafka_internal {
#   zone_id = data.aws_route53_zone.internal.zone_id
#   name    = "kafka-01.podspace.internal"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.test_instance.private_ip]
# }
#
# resource aws_route53_record kafka_external {
#   zone_id = data.aws_route53_zone.public.zone_id
#   name    = "kafka-test-server.podspace.net"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.test_instance.public_ip]
# }
#
# #-----------------------
#
