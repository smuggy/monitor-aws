output consul_one_volume_id {
  value = aws_ebs_volume.consul-one.id
}

output consul_two_volume_id {
  value = aws_ebs_volume.consul-two.id
}

output consul_three_volume_id {
  value = aws_ebs_volume.consul-three.id
}
