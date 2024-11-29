locals {
  website = {
    listeners = {
      main = {
        name                           = "main-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "www.contoso.com"
        require_sni                    = false
        certificate = {
          name                = "main-cert"
          key_vault_secret_id = module.kv.certs.main.secret_id
        }
        backend_pools = {
          app = {
            fqdns = ["app.internal"]
            http_settings = {
              main = {
                port      = 443
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
        routing = {
          rule_type        = "Basic"
          priority         = 100
          backend_pool     = "app"
          backend_settings = "main"
        }
      },
      old = {
        name                           = "old-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "old.contoso.com"
        require_sni                    = false
        certificate = {
          name                = "old-cert"
          key_vault_secret_id = module.kv.certs.old.secret_id
        }
        routing = {
          rule_type = "Basic"
          priority  = 200
          redirect_config = {
            target_listener = "main" # or target_url = "https://example.com"
            redirect_type   = "Permanent"
            include_path    = true
            include_query   = true
          }
        }
      }
    }
  }
}
