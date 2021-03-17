variable common_name {}

variable ca_cert_pem {}

variable ca_key_pem {}

variable ip_address {}

resource tls_private_key key {
  algorithm = "RSA"
}

resource tls_cert_request cert_req {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.key.private_key_pem
  dns_names       = [var.common_name, "localhost"]
  ip_addresses    = [var.ip_address, "127.0.0.1"]
  subject {
    common_name = var.common_name
  }
}

resource tls_locally_signed_cert cert {
  ca_private_key_pem    = var.ca_key_pem
  ca_key_algorithm      = "RSA"
  ca_cert_pem           = var.ca_cert_pem
  cert_request_pem      = tls_cert_request.cert_req.cert_request_pem
  allowed_uses          = ["digital_signature", "server_auth", "client_auth"]
  validity_period_hours = 365
}

resource local_file key {
  filename          = "../secrets/${var.common_name}-key.pem"
  sensitive_content = tls_private_key.key.private_key_pem
  file_permission   = 0440
}

resource local_file cert {
  filename        = "../secrets/${var.common_name}-cert.pem"
  content         = tls_locally_signed_cert.cert.cert_pem
  file_permission = 0444
}

output local_key_name {
  value = local_file.key.filename
}

output local_cert_name {
  value = local_file.cert.filename
}
