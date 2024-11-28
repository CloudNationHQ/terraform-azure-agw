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

#locals {
#sales = {
#rewrite_rule_sets = {
#security = {
#rules = {
#security_headers = {
#rule_sequence = 100
#conditions    = {}
#response_header_configurations = {
#security_policy = {
#header_name  = "Content-Security-Policy"
#header_value = "default-src 'self' *.sales.com"
#},
#hsts = {
#header_name  = "Strict-Transport-Security"
#header_value = "max-age=31536000"
#}
#}
#}
#}
#}
#},
#listeners = {
#sales = {
#name                           = "sales-listener"
#frontend_ip_configuration_name = "feip-prod-westus-001"
#frontend_port_name             = "fep-prod-westus-001"
#protocol                       = "Https"
#host_name                      = "sales.company.com"
#require_sni                    = false
#certificate = {
#name                = "sales-cert"
#key_vault_secret_id = module.kv.certs.sales.secret_id
#}
#backend_pools = {
#store = {
#fqdns = ["store.internal"]
#http_settings = {
#main = {
#port      = 8443
#protocol  = "Https"
#host_name = "store.internal"
#probe = {
#protocol = "Https"
#path     = "/health"
#host     = "store.internal"
#interval = 30
#timeout  = 30
#match = {
#body        = null
#status_code = ["200-399"]
#}
#}
#}
#}
#},
#checkout = {
#fqdns = ["checkout.internal"]
#http_settings = {
#main = {
#port      = 8443
#protocol  = "Https"
#host_name = "checkout.internal"
#probe = {
#protocol = "Https"
#path     = "/health"
#host     = "checkout.internal"
#interval = 30
#timeout  = 30
#match = {
#body        = null
#status_code = ["200-399"]
#}
#}
#}
#}
#}
#},
#routing = {
#rule_type             = "PathBasedRouting"
#priority              = 100
#rewrite_rule_set_name = "security"
#url_path_map = {
#default_pool                  = "store"
#default_settings              = "main"
#default_rewrite_rule_set_name = "security"
#path_rules = {
#checkout = {
#paths                 = ["/checkout/*"]
#pool                  = "checkout"
#settings              = "main"
#rewrite_rule_set_name = "security"
#}
#}
#}
#}
#}

#legacy = {
#name                           = "legacy-listener"
#frontend_ip_configuration_name = "feip-prod-westus-001"
#frontend_port_name             = "fep-prod-westus-001"
#protocol                       = "Https"
#host_name                      = "shop.company.com"
#require_sni                    = false
#certificate = {
#name                = "legacy-cert"
#key_vault_secret_id = module.kv.certs.legacy.secret_id
#}
#routing = {
#rule_type = "Basic"
#priority  = 200
#redirect_config = {
#target_listener = "sales" # or target_url = "https://example.com"
#redirect_type   = "Permanent"
#include_path    = true
#include_query   = true
#}
#}
#}
#}
#}
#}
