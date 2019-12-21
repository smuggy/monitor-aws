locals {
  vpc_id   = data.aws_vpc.utility_vpc.id
  region   = data.aws_region.current.name
  az_list  = ["${local.region}a", "${local.region}b", "${local.region}c"]
  subnet_map = {
    element(local.az_list, 0)  = data.aws_subnet.utility_subnet_one.id
    element(local.az_list, 1)  = data.aws_subnet.utility_subnet_two.id
    element(local.az_list, 2)  = data.aws_subnet.utility_subnet_three.id
  }
}

data aws_region current {}

data aws_security_group vpc_secgrp {
  name = local.secgrp_name
}

data aws_vpc utility_vpc {
  tags = {
    Name = "utility-us-east-2-vpc"
  }
}

data aws_subnet utility_subnet_one {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 0)
}

data aws_subnet utility_subnet_two {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 1)
}

data aws_subnet utility_subnet_three {
  vpc_id            = local.vpc_id
  availability_zone = element(local.az_list, 2)
}
