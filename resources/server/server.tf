locals {
  key_name = "utility-key"
}

resource aws_instance server {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = var.az
  key_name          = local.key_name
  subnet_id         = var.subnet_id

  vpc_security_group_ids = var.secgrps

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "${var.app}-server"
    Name        = "${var.app}-server-${var.server_number}"
  }
}

resource aws_volume_attachment volume_attachment {
  volume_id    = aws_ebs_volume.volume.id
  instance_id  = aws_instance.server.id
  device_name  = "/dev/sdf"
  force_detach = true
}

resource aws_ebs_volume volume {
  availability_zone = var.az
  size              = 4

  tags = {
    Name = "${var.app}_volume_${var.server_number}"
    App  = var.app
  }
}
