locals {
  key_name = "utility-key"
}

resource local_file private_key_file {
  sensitive_content    = module.utility_key_pair.private_key_pem
  filename             = "../secrets/utility-key"
  file_permission      = 0400
  directory_permission = 0755
}

resource local_file public_key_file {
  content              = module.utility_key_pair.public_key_ssh
  filename             = "../secrets/utility-key.pub"
  file_permission      = 0644
  directory_permission = 0755
}

module utility_key_pair {
  source = "git::https://github.com/smuggy/terraform-base//aws/compute/ssh_key_pair?ref=main"

  key_name = local.key_name
}

output key_pair_name {
  value = module.utility_key_pair.key_pair_name
}
