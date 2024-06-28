variable region {}
variable vpc_id {}
variable public_zone_id {}
variable internal_zone_id {}
variable reverse_zone_id {}
variable key_pair_name {}
variable public_subnet_map {}
variable cluster_count {
  type = number
  default = 1
}
variable az_list {
  type = list(string)
}