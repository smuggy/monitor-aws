locals {
  node_count   = 1
  vpc_id       = data.aws_vpc.utility_vpc.id
  subnet_id    = data.aws_subnet.utility_subnet.id
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  ami_owner    = "099720109477"    # Canonical Group Limited
  key_name     = "utility-key"
  ami_id       = data.aws_ami.ubuntu.id
  secgrp_name  = "utility_default_sg"
  region       = "us-east-2"

  availability_zone = "${local.region}b"

  internal_prometheus = "prometheus.utility.podspace.net"
  prometheus_host     = format("%s ansible_host=%s", local.internal_prometheus, aws_instance.prometheus_server.public_ip)

  internal_consul = "consul.utility.podspace.net"
  consul_host     = format("%s ansible_host=%s", local.internal_consul, aws_instance.consul_server.public_ip)
}

resource "aws_instance" "prometheus_server" {
  ami               = local.ami_id
  instance_type     = "t3.micro"
  availability_zone = local.availability_zone
#  count             = local.node_count

  key_name          = local.key_name
  subnet_id         = local.subnet_id
  user_data         = "si-01"

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.prometheus_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "prom-server"
  }
}

resource "aws_instance" "consul_server" {
  ami               = local.ami_id
  instance_type     = "t3.micro"
  availability_zone = local.availability_zone
  #  count             = local.node_count

  key_name          = local.key_name
  subnet_id         = local.subnet_id
  user_data         = "si-02"

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "consul-server"
  }
}

data "template_file" "all_hosts" {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [aws_instance.prometheus_server]
  vars = {
    prometheus_host_group = local.prometheus_host
    consul_host_group     = local.consul_host
  }
}

resource "null_resource" "hosts" {
  triggers = {
    template_rendered = data.template_file.all_hosts.rendered
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.all_hosts.rendered}' > all_hosts"
  }
}
