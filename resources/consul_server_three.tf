resource aws_instance consul_server_three {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_three
  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_three.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "consul-server"
    Name        = "consul-server-3"
  }
}

resource aws_volume_attachment consul_three_volume_attachment {
  volume_id    = aws_ebs_volume.consul_three.id
  instance_id  = aws_instance.consul_server_three.id
  device_name  = "/dev/sdf"
  force_detach = true
}

resource aws_ebs_volume consul_three {
  availability_zone = local.az_three
  size              = 4

  tags = {
    Name = "consul_three_volume"
    App  = "consul"
  }
}
