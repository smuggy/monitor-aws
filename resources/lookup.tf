data aws_security_group vpc_secgrp {
  name = local.secgrp_name
}

data aws_vpc utility_vpc {
  tags = {
    Name = "utility-us-east-2-vpc"
  }
}

data aws_subnet utility_subnet_one {
  vpc_id            = data.aws_vpc.utility_vpc.id
  availability_zone = local.az_one
}

data aws_subnet utility_subnet_two {
  vpc_id            = data.aws_vpc.utility_vpc.id
  availability_zone = local.az_two
}

data aws_subnet utility_subnet_three {
  vpc_id            = data.aws_vpc.utility_vpc.id
  availability_zone = local.az_three
}
