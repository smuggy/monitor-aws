resource aws_security_group prometheus_security_group {
  name   = "prometheus_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule prometheus_http {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
}

resource aws_security_group_rule prometheus_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 9090
  to_port           = 9090
}

resource aws_security_group_rule grafana_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 3000
  to_port           = 3000
}

resource aws_security_group consul_security_group {
  name   = "consul_sg"
  vpc_id = local.vpc_id
}

resource aws_security_group_rule consul_ui_tcp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 8500
  to_port           = 8500
}

resource aws_security_group_rule consul_dns_tcp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 8600
  to_port           = 8600
}

resource aws_security_group_rule consul_am_tcp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 9100
  to_port           = 9100
}

resource aws_security_group_rule consul_dns_udp {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 8600
  to_port           = 8600
}

resource aws_security_group_rule consul_self_all {
  security_group_id = aws_security_group.consul_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65000
  self              = true
}
