resource aws_instance server {
  ami               = local.ami_id
  instance_type     = var.instance_type
  availability_zone = var.az
  key_name          = var.key_name
  subnet_id         = var.subnet

  vpc_security_group_ids = var.sec_groups

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "${var.app}-server"
    Name        = "${var.app}-server-${substr(var.az, -1, 1)}${var.server_group}"
    NodeExport  = "true"
  }
}

resource aws_volume_attachment volume_attachment {
  volume_id    = aws_ebs_volume.volume[count.index].id
  instance_id  = aws_instance.server.id
  device_name  = "/dev/sdf"
  force_detach = true
  count        = var.volume_size > 0 ? 1 : 0
}

resource aws_ebs_volume volume {
  availability_zone = var.az
  size              = var.volume_size
  count             = var.volume_size > 0 ? 1 : 0

  tags = {
    Name = "${var.app}_volume_${var.server_group}"
    App  = var.app
  }
}
