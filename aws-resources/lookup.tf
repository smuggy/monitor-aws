locals {
  internal_domain    = "podspace.local"
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

#data aws_vpc utility_vpc {
#  tags = {
#    Name = "sb-utility-us-east-2"
#  }
#}
