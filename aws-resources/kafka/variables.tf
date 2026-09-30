variable region {}
variable vpc_id {}
variable public_zone_id {}
variable internal_zone_id {}
variable reverse_zone_id {}
variable key_pair_name {}
variable public_subnet_map {}
variable instance_type {
  type    = string
  default = "t3a.small"
}
variable az_list {
  type = list(string)
}
