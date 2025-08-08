locals {
  certs = {
    mobile = {
      issuer             = "Self"
      subject            = "CN=mobile.company.com"
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
