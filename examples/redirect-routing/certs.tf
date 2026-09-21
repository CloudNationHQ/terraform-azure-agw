locals {
  certs = {
    main = {
      issuer             = "Self"
      subject            = "CN=sales.company.com"
      validity_in_months = 12
      exportable         = true
      key_type           = "RSA"
      key_size           = 2048
      reuse_key          = true
      content_type       = "application/x-pkcs12"
      key_usage = [
        "cRLSign", "dataEncipherment",
        "digitalSignature", "keyAgreement",
        "keyCertSign", "keyEncipherment"
      ]
    }
    old = {
      issuer             = "Self"
      subject            = "CN=legacy.company.com"
      validity_in_months = 12
      exportable         = true
      key_type           = "RSA"
      key_size           = 2048
      reuse_key          = true
      content_type       = "application/x-pkcs12"
      key_usage = [
        "cRLSign", "dataEncipherment",
        "digitalSignature", "keyAgreement",
        "keyCertSign", "keyEncipherment"
      ]
    }
  }
}
