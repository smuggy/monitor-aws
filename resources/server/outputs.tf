output private_ip {
  value = aws_instance.server.private_ip
}

output public_ip {
  value = aws_instance.server.public_ip
}

output instance_id {
  value = aws_instance.server.id
}

output instance_name {
  value = local.name
}
