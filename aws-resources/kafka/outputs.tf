output kafka_host_group {
  value = local.kafka_host_group
}

output schema_registry_host_group {
  value = local.schema_registry_host_group
}

output raft_id {
  value = local.raft_id
}

output kafka_ips {
  value = module.brokers.*.public_ip
}

output registry_ip {
  value = module.registry.public_ip
}
