locals {
  ami_owner    = "099720109477"    # Canonical Group Limited
  ami_id       = data.aws_ami.ubuntu.id
}

# 18.04 LTS Bionic amd 64 hvm:ebs-ssd
data aws_ami ubuntu {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [local.ami_owner]  # Canonical Group Limited
}
