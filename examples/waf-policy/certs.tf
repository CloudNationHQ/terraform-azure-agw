locals {
  certs = {
    webapp = {
      issuer             = "Self"
      subject            = "CN=app.company.com"
      validity_in_months = 12
      exportable         = true
      key_usage = [
        "cRLSign", "dataEncipherment",
        "digitalSignature", "keyAgreement",
        "keyCertSign", "keyEncipherment"
      ]
    }
  }
}
