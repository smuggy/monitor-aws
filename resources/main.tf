locals {
  node_count   = 1
  vpc_id       = data.aws_vpc.utility_vpc.id
  subnet_id    = data.aws_subnet.utility_subnet.id
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  ami_owner    = "099720109477"
  key_name     = "utility-key"
  ami_id       = data.aws_ami.ubuntu.id
  secgrp_name  = "utility_default_sg"
  region       = "us-east-2"

  availability_zone = "${local.region}b"

  prometheus_hosts    = formatlist("ps-%d.utility.podspace.net ansible_host=%s", range(local.node_count), aws_instance.prometheus_servers.*.public_ip)
  internal_prometheus = formatlist("ps-%d.utility.podspace.net", range(local.node_count))
}

resource "aws_instance" "prometheus_servers" {
  ami               = local.ami_id
  instance_type     = "t3.micro"
  availability_zone = local.availability_zone
  count             = local.node_count

  key_name          = local.key_name
  subnet_id         = local.subnet_id
  user_data         = "si-${format("%02d", count.index)}"

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.prometheus_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "prom-server"
  }
}

data "template_file" "all_hosts" {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [aws_instance.prometheus_servers]
  vars = {
    prometheus_host_group = join("\n", local.prometheus_hosts)
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
