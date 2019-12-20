resource aws_instance consul_server_two {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_two
  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_two.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "consul-server"
    Name        = "consul-server-2"
  }
}

resource aws_volume_attachment consul_two_volume_attachment {
  volume_id    = aws_ebs_volume.consul_two.id
  instance_id  = aws_instance.consul_server_two.id
  device_name  = "/dev/sdf"
  force_detach = true
}

resource aws_ebs_volume consul_two {
  availability_zone = local.az_two
  size              = 4

  tags = {
    Name = "consul_two_volume"
    App  = "consul"
  }
}
