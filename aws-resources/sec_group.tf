resource aws_security_group prometheus_security_group {
  name   = "prometheus_sg"
  vpc_id = local.vpc_id
  tags = {
    Name = "prometheus_sg"
  }
}

resource aws_security_group_rule prometheus_https {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}

resource aws_security_group_rule prometheus_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 9000
  to_port           = 9100
}

resource aws_security_group_rule grafana_tcp {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  from_port         = 3000
  to_port           = 3000
}

resource aws_security_group_rule http_out {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule https_out {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
