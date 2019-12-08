resource aws_volume_attachment consul_one_volume_attachment {
  volume_id    = data.aws_ebs_volume.consul_one_volume.volume_id
  instance_id  = aws_instance.consul_server-1.id
  device_name  = "/dev/sdf"
  force_detach = true
}

resource aws_volume_attachment consul_two_volume_attachment {
  volume_id    = data.aws_ebs_volume.consul_two_volume.volume_id
  instance_id  = aws_instance.consul_server-2.id
  device_name  = "/dev/sdf"
  force_detach = true
}

resource aws_volume_attachment consul_three_volume_attachment {
  volume_id    = data.aws_ebs_volume.consul_three_volume.volume_id
  instance_id  = aws_instance.consul_server-3.id
  device_name  = "/dev/sdf"
  force_detach = true
}
