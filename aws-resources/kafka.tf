module kafka {
  source = "./kafka"

  region            = local.region
  internal_zone_id  = data.aws_route53_zone.internal.zone_id
  public_zone_id    = data.aws_route53_zone.public.zone_id
  reverse_zone_id   = data.aws_route53_zone.reverse.zone_id
  az_list           = local.az_list
  public_subnet_map = local.public_subnet_map
  vpc_id            = local.vpc_id
  key_pair_name     = module.utility_key_pair.key_pair_name
}

resource local_file kafka_group_file {
  filename        = "../infra/group_vars/kafka_servers"
  content         = templatefile("templates/kafka_groups_vars.tpl",
    {
      region     = local.region
      raft_id    = module.kafka.raft_id
      zk_servers = format("%s:2181", local.kafka_zk)
      zookeeper  = "true"
    })
  file_permission = 0644
}

module zookeeper {
  source = "./zookeeper"

  cluster_count     = 1
  region            = local.region
  internal_zone_id  = data.aws_route53_zone.internal.zone_id
  public_zone_id    = data.aws_route53_zone.public.zone_id
  reverse_zone_id   = data.aws_route53_zone.reverse.zone_id
  az_list           = local.az_list
  public_subnet_map = local.public_subnet_map
  vpc_id            = local.vpc_id
  key_pair_name     = module.utility_key_pair.key_pair_name
}

locals {
  server_map = join("\n  - ", module.zookeeper.zookeeper_server_list)
  zk_servers = format("  - %s", local.server_map)
  id_map     = join("\n  ", module.zookeeper.id_map)
  id_map_s   = format("  %s", local.id_map)
  kafka_zk   = join(",", module.zookeeper.zookeeper_server_names)
}

resource local_file zookeeper_group_file {
  filename        = "../infra/group_vars/zookeeper_servers"
  content         = templatefile("templates/zookeeper_groups_vars.tpl",
    {
      region     = local.region
      server_map = local.zk_servers
      id_map     = local.id_map_s
    })
  file_permission = 0644
}
