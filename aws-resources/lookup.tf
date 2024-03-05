locals {
  internal_domain    = "podspace.internal"
  external_domain    = "podspace.net"
  vpc_id             = data.aws_vpc.utility_vpc.id
  region             = data.aws_region.current.name
  az_list             = ["${local.region}a","${local.region}b","${local.region}c"]
  public_subnet_map = {
    element(local.az_list, 0)  = data.aws_subnet.public_subnet_one.id
    element(local.az_list, 1)  = data.aws_subnet.public_subnet_two.id
    element(local.az_list, 2)  = data.aws_subnet.public_subnet_three.id
  }
}

data aws_region current {}

data aws_vpc utility_vpc {
  tags = {
    Name = "sb-utility-us-east-2"
  }
}

data aws_route53_zone internal {
  name         = local.internal_domain
  private_zone = true
}

data aws_route53_zone reverse {
  name         = "20.10.in-addr.arpa"#local.reverse_zone
  private_zone = true
}

data aws_route53_zone public {
  name = "podspace.net" #local.external_domain
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
