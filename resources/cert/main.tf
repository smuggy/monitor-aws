variable common_name {
  type = list
}

variable mcount {}

variable ca_cert_pem {}

variable ca_key_pem {}

variable ips {
  type = list
}

resource tls_private_key key {
  count = var.mcount

  algorithm = "RSA"
}

resource tls_cert_request cert_req {
  count = var.mcount

  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.key.*.private_key_pem[count.index]
  dns_names       = [var.common_name[count.index]]
  ip_addresses    = [var.ips[count.index]]
  subject {
    common_name = var.common_name[count.index]
  }
}

resource tls_locally_signed_cert cert {
  count = var.mcount

  ca_private_key_pem    = var.ca_key_pem
  ca_key_algorithm      = "RSA"
  ca_cert_pem           = var.ca_cert_pem
  cert_request_pem      = tls_cert_request.cert_req.*.cert_request_pem[count.index]
  allowed_uses          = ["digital_signature", "server_auth", "client_auth"]
  validity_period_hours = 365
}

resource local_file key {
  count = var.mcount

  filename          = "../secrets/${var.common_name[count.index]}-key.pem"
  sensitive_content = tls_private_key.key.*.private_key_pem[count.index]
  file_permission   = "0440"
}

resource local_file cert {
  count = var.mcount

  filename        = "../secrets/${var.common_name[count.index]}-cert.pem"
  content         = tls_locally_signed_cert.cert.*.cert_pem[count.index]
  file_permission = "0444"
}

output local_key_name {
  value = local_file.key.*.filename
}

output local_cert_name {
  value = local_file.cert.*.filename
}