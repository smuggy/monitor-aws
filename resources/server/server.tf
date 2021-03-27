locals {
  name = format("%s%s%s%02d%s%1s%02d",
  lookup(local.env_types, var.environment,"x"),
  lookup(local.region_map, var.region, "x"),
  substr(var.app, 0, 4),
  var.server_group,
  substr(var.server_type, 0, 3),
  substr(var.az, -1, 1),
  var.server_number)

  env_types = {
    "sandbox" = "s"
    "dev"     = "d"
    "test"    = "t"
    "prod"    = "p"
  }

  region_map = {
    "us-east-1" = "v"
    "us-east-2" = "o"
    "us-west-1" = "c"
    "us-west-2" = "r"
  }
}

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
    ServerGroup = "${var.app}-server-${var.server_group}"
    Name        = local.name
    NodeExport  = var.export_stats ? "true" : "false"
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

resource aws_route53_record instance_reverse {
  zone_id = var.reverse_zone_id
  type    = "PTR"
  name    = join(".",
                 reverse(regex("[[:digit:]]*.[[:digit:]]*.([[:digit:]]*).([[:digit:]]*)",
                 aws_instance.server.private_ip)))
  ttl     = "300"
  records = [local.name]
}

resource aws_route53_record internal {
  zone_id = var.name_zone_id
  type    = "A"
  ttl     = 300
  name    = local.name
  records = [aws_instance.server.private_ip]
}
