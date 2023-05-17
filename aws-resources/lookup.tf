locals {
  internal_domain    = "podspace.internal"
  external_domain    = "podspace.net"
  vpc_id             = data.aws_vpc.scratch_vpc.id
  region             = data.aws_region.current.name
}

data aws_region current {}

data aws_vpc scratch_vpc {
  tags = {
    Name = "sb-scratch-us-east-2"
  }
}
