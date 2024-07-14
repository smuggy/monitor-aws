provider: aws
region: ${region}
raft_id: ${raft_id}
zookeeper: ${zookeeper}
zk_servers: ${zk_servers}
node_id_map:
  kafka-00.podspace.internal: 1
  kafka-01.podspace.internal: 2
  kafka-02.podspace.internal: 3
