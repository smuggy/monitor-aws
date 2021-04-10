locals {
  internal_domain    = "podspace.local"
  external_domain    = "podspace.net"
  vpc_id             = data.aws_vpc.scratch_vpc.id
  region             = data.aws_region.current.name
  vpc_cidr           = data.aws_vpc.scratch_vpc.cidr_block
  az_list            = ["${local.region}a", "${local.region}b", "${local.region}c"]
  sec_group_name     = "default"
  sec_group_id       = data.aws_security_group.vpc_sec_group.id
  public_subnet_map  = {
    element(local.az_list, 0)  = data.aws_subnet.public_subnet_one.id
    element(local.az_list, 1)  = data.aws_subnet.public_subnet_two.id
    element(local.az_list, 2)  = data.aws_subnet.public_subnet_three.id
  }
  private_subnet_map = {
    element(local.az_list, 0)  = data.aws_subnet.private_subnet_one.id
    element(local.az_list, 1)  = data.aws_subnet.private_subnet_two.id
    element(local.az_list, 2)  = data.aws_subnet.private_subnet_three.id
  }
}

data aws_region current {}

data aws_security_group vpc_sec_group {
  name   = local.sec_group_name
  vpc_id = local.vpc_id
}

data aws_vpc scratch_vpc {
  tags = {
    Name = "sb-scratch-us-east-2"
  }
}

data aws_subnet public_subnet_one {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 0)
  filter {
    name = "tag:use"
    values = ["public"]
  }
}

data aws_subnet public_subnet_two {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 1)
  filter {
    name = "tag:use"
    values = ["public"]
  }
}

data aws_subnet public_subnet_three {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 2)
  filter {
    name = "tag:use"
    values = ["public"]
  }
}

data aws_subnet private_subnet_one {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 0)
  filter {
    name = "tag:use"
    values = ["private"]
  }
}

data aws_subnet private_subnet_two {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 1)
  filter {
    name = "tag:use"
    values = ["private"]
  }
}

data aws_subnet private_subnet_three {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 2)
  filter {
    name = "tag:use"
    values = ["private"]
  }
}

//data aws_eip prometheus_ip {
//  filter {
//    name = "tag:Name"
//    values = ["prometheus-ip"]
//  }
//}
//
//output prometheus_ip {
//  description = "Public ip of the prometheus server (Elastic IP)."
//  value       = data.aws_eip.prometheus_ip.public_ip
//}
