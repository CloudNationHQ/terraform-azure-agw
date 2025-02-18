locals {
  catalyst = {
    listeners = {
      global = {
        frontend_ip_configuration_name = "public"
        frontend_port_name             = "https"
        protocol                       = "Https"
        host_name                      = "app.company.com"
        require_sni                    = false
        certificate = {
          name                = "global-cert"
          key_vault_secret_id = module.kv.certs.global.secret_id
        }
        backend_address_pools = {
          blue = {
            fqdns = ["blue.internal"]
          }
          green = {
            fqdns = ["green.internal"]
          }
        }
        routing_rule = {
          rule_type = "PathBasedRouting"
          priority  = 100
          url_path_map = {
            default_backend_address_pool_name  = "blue"
            default_backend_http_settings_name = "blue"
            default_rewrite_rule_set_name      = "headers_blue"
            path_rules = {
              api = {
                paths                      = ["/api/*"]
                backend_address_pool_name  = "green"
                backend_http_settings_name = "green"
                rewrite_rule_set_name      = "headers_green"
              }
              web = {
                paths                      = ["/web/*"]
                backend_address_pool_name  = "green"
                backend_http_settings_name = "green"
                rewrite_rule_set_name      = "headers_green"
              }
            }
          }
        }
      }
      europe = {
        frontend_ip_configuration_name = "private"
        frontend_port_name             = "http"
        protocol                       = "Http"
        host_name                      = "app.company.eu"
        require_sni                    = false
        backend_address_pools = {
          blue = {
            fqdns = ["eu-blue.internal"]
          }
          green = {
            fqdns = ["eu-green.internal"]
          }
        }
        routing_rule = {
          rule_type = "PathBasedRouting"
          priority  = 110
          url_path_map = {
            default_backend_address_pool_name  = "blue"
            default_backend_http_settings_name = "main"
            default_rewrite_rule_set_name      = "headers_blue"
            path_rules = {
              api = {
                paths                      = ["/api/*"]
                backend_address_pool_name  = "green"
                backend_http_settings_name = "main"
                rewrite_rule_set_name      = "headers_green"
              }
            }
          }
        }
      }
      america = {
        frontend_ip_configuration_name = "private"
        frontend_port_name             = "http"
        protocol                       = "Http"
        host_name                      = "app.company.us"
        require_sni                    = false
        backend_address_pools = {
          blue = {
            fqdns = ["us-blue.internal"]
          }
          green = {
            fqdns = ["us-green.internal"]
          }
        }
        routing_rule = {
          rule_type                  = "Basic"
          priority                   = 130
          backend_http_settings_name = "main"
          backend_address_pool_name  = "blue"
        }
      }
      asia = {
        frontend_ip_configuration_name = "private"
        frontend_port_name             = "http"
        protocol                       = "Http"
        host_name                      = "app.company.as"
        require_sni                    = false
        backend_address_pools = {
          blue = {
            fqdns = ["as-blue.internal"]
          }
          green = {
            fqdns = ["as-green.internal"]
          }
        }
        routing_rule = {
          rule_type                   = "Basic"
          priority                    = 120
          redirect_configuration_name = "to_global"
        }
      }
      africa = {
        frontend_ip_configuration_name = "private"
        frontend_port_name             = "http"
        protocol                       = "Http"
        host_name                      = "app.company.af"
        require_sni                    = false
        backend_address_pools = {
          blue = {
            fqdns = ["af-blue.internal"]
          }
          green = {
            fqdns = ["af-green.internal"]
          }
        }
        routing_rule = {
          rule_type = "PathBasedRouting"
          priority  = 140
          url_path_map = {
            default_redirect_configuration_name = "to_url"
            default_rewrite_rule_set_name       = "headers_blue"
            path_rules = {
              api = {
                paths                       = ["/api/*"]
                redirect_configuration_name = "to_global"
                rewrite_rule_set_name       = "headers_green"
              }
            }
          }
        }
      }
    }
    backend_http_settings = {
      blue = {
        port      = 8080
        protocol  = "Https"
        host_name = "blue.internal"
        probe = {
          path                                      = "/health"
          pick_host_name_from_backend_http_settings = true
          interval                                  = 30
          timeout                                   = 30
          match = {
            body        = null
            status_code = ["200-399"]
          }
        }
      }
      green = {
        port      = 8080
        protocol  = "Https"
        host_name = "green.internal"
        probe = {
          path                                      = "/health"
          pick_host_name_from_backend_http_settings = true
          interval                                  = 30
          timeout                                   = 30
          match = {
            status_code = ["200-399"]
          }
        }
      }
      main = {
        port      = 8080
        protocol  = "Https"
        host_name = "eu-blue.internal"
        probe = {
          path                                      = "/health"
          pick_host_name_from_backend_http_settings = true
          interval                                  = 30
          timeout                                   = 30
          match = {
            body        = null
            status_code = ["200-399"]
          }
        }
      }
    }
  }
}
