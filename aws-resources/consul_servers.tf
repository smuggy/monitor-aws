locals {
#  consul_server_count    = module.consul_cluster.cluster_server_count
#  consul_hosts           = formatlist("%s ansible_host=%s", module.consul_cluster.server_names, module.consul_cluster.private_ips)
#  internal_consul_string = join("\n  - ", module.consul_cluster.server_names)
#  consul_host_group      = join("\n", local.consul_hosts)
  consul_host_group      = ""
}
#
#module consul_cluster {
#  source = "git::https://github.com/smuggy/tf-services//consul?ref=main"
#
#  cluster_size  = "medium"
#  instance_type = "t3a.micro"
#  server_group  = "1"
#  vpc_id        = local.vpc_id
#  ssh_key_name  = local.key_name
#  region        = local.region
#  ca_cert       = file("../../vpcs/secrets/local_ca_cert.pem")
#  ca_key        = file("../../vpcs/secrets/local_ca_key.pem")
#}
#
#resource null_resource consul_groups_vars {
#  triggers = {
#    root_ip = join(",", sort(module.consul_cluster.private_ips))
#  }
#  provisioner local-exec {
#    command = "echo '${module.consul_cluster.cluster_config}' > ../infra/group_vars/consul_servers"
#  }
#}
#
#resource random_id gossip_key {
#  byte_length = 32
#}
#
#resource local_file gossip_key {
#  filename = "../secrets/gossip_key"
#  content  = random_id.gossip_key.b64_std
#}
#
#resource local_file key {
#  count = local.consul_server_count
#
#  filename          = "../secrets/${element(module.consul_cluster.server_names, count.index)}-key.pem"
#  sensitive_content = element(module.consul_cluster.consul_keys, count.index)
#  file_permission   = 0440
#}
#
#resource local_file cert {
#  count = local.consul_server_count
#
#  filename        = "../secrets/${element(module.consul_cluster.server_names, count.index)}-cert.pem"
#  content         = element(module.consul_cluster.consul_certs, count.index)
#  file_permission = 0444
#}
#
#output consul_private_ips {
#  description = "Private ips for consul servers"
#  value       = module.consul_cluster.private_ips
#}
