locals {
  node_count   = 1
  vpc_id       = data.aws_vpc.utility_vpc.id
  secgrp_id    = data.aws_security_group.vpc_secgrp.id
  ami_owner    = "099720109477"    # Canonical Group Limited
  key_name     = "utility-key"
  ami_id       = data.aws_ami.ubuntu.id
  secgrp_name  = "utility_default_sg"
  region       = "us-east-2"

  az_one   = "${local.region}a"
  az_two   = "${local.region}b"
  az_three = "${local.region}c"

  internal_prometheus = "prometheus.utility.podspace.net"
  prometheus_host     = format("%s ansible_host=%s", local.internal_prometheus, aws_instance.prometheus_server.public_ip)

  internal_consul     = formatlist("consul-%02d.utility.podspace.net", range(3))
  consul_private_ips  = [aws_instance.consul_server-1.private_ip,
                        aws_instance.consul_server-2.private_ip,
                        aws_instance.consul_server-3.private_ip]
#  consul_private_list = formatlist("\"%s\"", local.consul_private_ips)
  consul_public_ips   = [aws_instance.consul_server-1.public_ip,
                        aws_instance.consul_server-2.public_ip,
                        aws_instance.consul_server-3.public_ip]
  consul_hosts        = formatlist("%s ansible_host=%s", local.internal_consul, local.consul_public_ips)

}

resource aws_instance "prometheus_server" {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_two

  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_two.id
  user_data         = "si-01"

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.prometheus_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "prom-server"
  }
}

resource aws_instance "consul_server-1" {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_one
  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_one.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "consul-server"
    Name        = "consul-server-1"
  }
}

resource aws_instance "consul_server-2" {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_two
  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_two.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "consul-server"
    Name        = "consul-server-2"
  }
}

resource aws_instance "consul_server-3" {
  ami               = local.ami_id
  instance_type     = "t3a.micro"
  availability_zone = local.az_three
  key_name          = local.key_name
  subnet_id         = data.aws_subnet.utility_subnet_three.id

  vpc_security_group_ids = [local.secgrp_id, aws_security_group.consul_security_group.id]

  root_block_device {
    volume_size = 10
  }

  tags = {
    ServerGroup = "consul-server"
    Name        = "consul-server-3"
  }
}

data template_file "all_hosts" {
  template = file("${path.module}/templates/hosts.cfg")
  depends_on = [aws_instance.prometheus_server]
  vars = {
    prometheus_host_group = local.prometheus_host
    consul_host_group     = join("\n", local.consul_hosts)
  }
}

resource null_resource "hosts" {
  triggers = {
    template_rendered = data.template_file.all_hosts.rendered
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.all_hosts.rendered}' > ../infra/all_hosts"
  }
}

resource null_resource "consul_groups_vars" {
  triggers = {
    root_ip = aws_instance.consul_server-1.private_ip
  }
  provisioner "local-exec" {
    command = "echo 'root_agent_ips:\n  - ${join("\n  - ", local.consul_private_ips)}\n' > ../infra/group_vars/consul_servers"
  }
}

resource null_resource "prom_groups_vars" {
  triggers = {
    root_ip = aws_instance.consul_server-1.private_ip
  }
  provisioner "local-exec" {
    command = "echo 'consul_names:\n  - ${join("\n  - ", local.internal_consul)}\n' > ../infra/group_vars/prom_servers"
  }
}
