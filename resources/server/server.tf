resource aws_instance server {
  count             = var.server_count
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = element(var.az_list, count.index)
  key_name          = var.key_name
  subnet_id         = var.subnet_map[element(var.az_list, count.index)]

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
  volume_id    = element(aws_ebs_volume.volume.*.id, count.index)
  instance_id  = element(aws_instance.server.*.id, count.index)
  device_name  = "/dev/sdf"
  force_detach = true
  count        = var.volume_size > 0 ? var.server_count : 0
}

resource aws_ebs_volume volume {
  availability_zone = element(var.az_list, count.index)
  size              = var.volume_size
  count             = var.volume_size > 0 ? var.server_count : 0

  tags = {
    Name = "${var.app}_volume_${var.server_number}"
    App  = var.app
  }
}
