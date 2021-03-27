variable region {
  description = "region where this is created"
}

variable environment {
  description = "environment type"
  default     = "sandbox"
}

variable az {
  description = "availability zone where the instance will be placed"
  type        = string
}

variable subnet {
  description = "subnet id where the instance will be placed"
  type        = string
}

variable sec_groups {
  description = "security groups for the instance."
  type        = list(string)
}

variable app {
}

variable volume_size {
  default = 0
  type    = number
}

variable server_group {
  default = 1
  type    = number
}

variable server_number {
  default = 1
  type    = number
}

//variable server_count {
//  default = 1
//  type    = number
//}

variable key_name {
}

variable instance_type {
  default = "t3a.micro"
}

variable server_type {
  default = "srv"
}

variable name_zone_id {
}

variable reverse_zone_id {
}

variable export_stats {
  type    = bool
  default = true
}