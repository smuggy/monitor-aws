locals {
  internal_domain    = "podspace.internal"
  external_domain    = "podspace.net"
  vpc_id             = data.aws_vpc.utility_vpc.id
  region             = data.aws_region.current.name
}

data aws_region current {}

data aws_vpc utility_vpc {
  tags = {
    Name = "sb-utility-us-east-2"
  }
}
