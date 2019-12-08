resource aws_instance "consul_server_one" {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_one
  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_one.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "consul-server"
    Name        = "consul-server-1"
  }
}

resource aws_volume_attachment consul_one_volume_attachment {
  volume_id    = aws_ebs_volume.consul_one.id
  instance_id  = aws_instance.consul_server_one.id
  device_name  = "/dev/sdf"
  force_detach = true
}

resource aws_ebs_volume consul_one {
  availability_zone = local.az_one
  size              = 4

  tags = {
    Name = "consul_one_volume"
    App  = "consul"
  }
}
