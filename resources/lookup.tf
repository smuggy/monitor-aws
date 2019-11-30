data "aws_security_group" "vpc_secgrp" {
  name = local.secgrp_name
}

data "aws_vpc" "utility_vpc" {
  tags = {
    Name = "utility-us-east-2-vpc"
  }
}

data "aws_subnet" "utility_subnet" {
  vpc_id            = data.aws_vpc.utility_vpc.id
  availability_zone = local.availability_zone
}

# 18.04 LTS Bionic amd 64 hvm:ebs-ssd
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [local.ami_owner]  # Canonical Group Limited
}