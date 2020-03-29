locals {
  ws_count       = 2
  internal_ws    = formatlist("ws-%02d.utility.podspace.net", range(local.ws_count))
  ws_private_ips = module.ws_servers.private_ip
  ws_public_ips  = module.ws_servers.public_ip
  ws_hosts       = formatlist("%s ansible_host=%s", local.internal_ws, local.ws_public_ips)
}

module ws_servers {
  source        = "./server"
  server_number = 1
  az_list       = local.az_list_two
  subnet_map    = local.subnet_map_two
  secgrps       = [local.secgrp_id, aws_security_group.ws_security_group.id]
  app           = "web"
  volume_size   = 4
  server_count  = local.ws_count
  key_name      = local.key_name
}

resource aws_security_group ws_security_group {
  name   = "ws_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule ws_ui_tcp {
  security_group_id = aws_security_group.ws_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 80
  to_port           = 80
}

output ws_public_ips {
  description = "Public ips for ws servers"
  value       = local.ws_public_ips
}

resource aws_lb ws_service {
  name               = "ws-lb-tf"
  internal           = true
  load_balancer_type = "network"
  subnets            = [
//    data.aws_subnet.utility_subnet_one.id,
    data.aws_subnet.utility_subnet_two.id,
    data.aws_subnet.utility_subnet_three.id]

  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}

resource aws_lb_listener http {
  load_balancer_arn = aws_lb.ws_service.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource aws_lb_target_group http {
  name     = "tg-ws-http"
  port     = 80
  protocol = "TCP"
  vpc_id   = local.vpc_id
}

resource aws_lb_target_group_attachment http {
  count            = local.ws_count
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = element(module.ws_servers.instance_id, count.index)
  port             = 80
}
