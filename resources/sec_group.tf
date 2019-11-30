resource "aws_security_group" "prometheus_security_group" {
  name   = "prometheus_sg"
  vpc_id = local.vpc_id
}

resource "aws_security_group_rule" "prometheus_tcp" {
  security_group_id = aws_security_group.prometheus_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9090
  to_port           = 9090
}
