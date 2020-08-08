variable az_list {
  description = "availability zone where the instance will be placed"
  type        = list
}

variable subnet_map {
  description = "subnet id where the instance will be placed"
  type        = map
}

variable secgrps {
  description = "security groups for the instance."
  type        = list
}

variable app {
}

variable volume_size {
  default = 0
  type    = number
}

variable server_count {
  default = 1
  type    = number
}

variable key_name {

}

variable instance_type {
  default = "t3a.micro"
}