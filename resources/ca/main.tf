resource tls_private_key ca_key {
  algorithm = "RSA"
}

resource tls_self_signed_cert ca_cert {
  allowed_uses          = ["digital_signature", "cert_signing", "crl_signing"]
  key_algorithm         = "RSA"
  private_key_pem       = tls_private_key.ca_key.private_key_pem
  validity_period_hours = 10000
  is_ca_certificate     = true
  subject {
    common_name  = "elk_ca"
    organization = "podspace.net"
  }
}

resource local_file ca_key {
  filename          = "../secrets/elk_ca_key.pem"
  sensitive_content = tls_private_key.ca_key.private_key_pem
  file_permission   = "0440"
}

resource local_file ca_cert {
  filename = "../secrets/elk_ca.pem"
  content  = tls_self_signed_cert.ca_cert.cert_pem
}

output ca_key_pem {
  value = tls_private_key.ca_key.private_key_pem
}

output ca_cert_pem {
  value = tls_self_signed_cert.ca_cert.cert_pem
}

output ca_name {
  value = local_file.ca_cert.filename
}
