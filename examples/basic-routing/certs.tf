locals {
  certs = {
    api = {
      issuer             = "Self"
      subject            = "CN=api.company.com"
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
