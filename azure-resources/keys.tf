resource tls_private_key key {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file private_key_file {
  sensitive_content    = tls_private_key.key.private_key_pem
  filename             = "../secrets/consul-key"
  file_permission      = 0400
  directory_permission = 0755
}

resource local_file public_key_file {
  content              = tls_private_key.key.public_key_openssh
  filename             = "../secrets/consul-key.pub"
  file_permission      = 0644
  directory_permission = 0755
}
