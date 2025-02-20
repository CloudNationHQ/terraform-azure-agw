locals {
  webapp = {
    listeners = {
      webapp = {
        name                           = "webapp-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "webapp.company.com"
        require_sni                    = false
        certificate = {
          name                = "webapp-cert"
          key_vault_secret_id = module.kv.certs.webapp.secret_id
        }
        routing_rule = {
          rule_type                  = "Basic"
          priority                   = 100
          backend_address_pool_name  = "primary"
          backend_http_settings_name = "main"
        }
      }
    }
    backend_address_pools = {
      primary = {
        fqdns = ["app.internal"]
      }
    }
    backend_http_settings = {
      main = {
        port      = 8080
        protocol  = "Https"
        host_name = "app.internal"
        probe = {
          protocol = "Https"
          path     = "/health"
          host     = "app.internal"
          interval = 30
          timeout  = 30
          match = {
            body        = null
            status_code = ["200-399"]
          }
        }
      }
    }
  }
}
