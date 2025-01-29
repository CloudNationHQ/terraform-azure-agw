locals {
  certs = {
    global = {
      issuer             = "Self"
      subject            = "CN=app.company.com"
      validity_in_months = 12
      exportable         = true
      key_usage = [
        "cRLSign", "dataEncipherment",
        "digitalSignature", "keyAgreement",
        "keyCertSign", "keyEncipherment"
      ]
    },
    europe = {
      issuer             = "Self"
      subject            = "CN=app.company.eu"
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
