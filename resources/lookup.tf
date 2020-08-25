locals {
  vpc_id      = data.aws_vpc.utility_vpc.id
  region      = data.aws_region.current.name
  az_list     = ["${local.region}a", "${local.region}b", "${local.region}c"]
  secgrp_name = "default"
  secgrp_id   = data.aws_security_group.vpc_secgrp.id
  subnet_map  = {
    element(local.az_list, 0)  = data.aws_subnet.utility_subnet_one.id
    element(local.az_list, 1)  = data.aws_subnet.utility_subnet_two.id
    element(local.az_list, 2)  = data.aws_subnet.utility_subnet_three.id
  }
}

data aws_region current {}

data aws_security_group vpc_secgrp {
  name   = local.secgrp_name
  vpc_id = local.vpc_id
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

//
//resource null_resource cr {
//  count = 1
//  triggers = {
//    vpc_id = local.vpc_id
//  }
//  provisioner local-exec {
//    command = "aws route53 list-hosted-zones-by-vpc
//                --region ${local.region} --vpc-region ${local.region}
//                --vpc-id ${local.vpc_id} --output text --query 'HostedZoneSummaries[].[HostedZoneId,Name]'
//                | grep podspace > ${path.module}/t1.out"
//  }
//  provisioner local-exec {
//    command = "a=$(cat ${path.module}/t1.out) && echo $(sed 's/ .*//' <<< $a) > ${path.module}/t2.out"
//  }
//}
//
//data null_data_source namezone {
//  count = 1
//  depends_on = [null_resource.cr]
//  inputs = {
//    value = file("${path.module}/t2.out")
//  }
//}
