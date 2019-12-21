variable az {
  description = "availability zone where the instance will be placed"
}

variable subnet_id {
  description = "subnet id where the instance will be placed"
}

variable secgrps {
  description = "security groups for the instance."
  type        = list
}

variable server_number {
  type = number
}

variable app {
}

variable volume_size {
  default = 0
  type    = number
}