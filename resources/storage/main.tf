locals {
  region       = "us-east-2"

  az_one   = "${local.region}a"
  az_two   = "${local.region}b"
  az_three = "${local.region}c"
}
resource "aws_ebs_volume" "consul-one" {
  availability_zone = local.az_one
  size              = 4

  tags = {
    Name = "consul-one"
    App  = "consul"
  }
}

resource "aws_ebs_volume" "consul-two" {
  availability_zone = local.az_two
  size              = 4

  tags = {
    Name = "consul-two"
    App  = "consul"
  }
}

resource "aws_ebs_volume" "consul-three" {
  availability_zone = local.az_three
  size              = 4

  tags = {
    Name = "consul-three"
    App  = "consul"
  }
}
