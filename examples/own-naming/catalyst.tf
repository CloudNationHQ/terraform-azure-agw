locals {
  catalyst = {
    listeners = {
      global = {
        name                           = "listener-${module.naming.application_gateway.name}-global"
        frontend_ip_configuration_name = "public-ip-configuration"
        frontend_port_name             = "frontend-port-https"
        protocol                       = "Https"
        host_name                      = "app.company.com"
        require_sni                    = false
        certificate = {
          name                = "cert-${module.naming.application_gateway.name}-global"
          key_vault_secret_id = module.kv.certs.global.secret_id
        }
        backend_address_pools = {
          blue = {
            name  = "pool-${module.naming.application_gateway.name}-global-blue"
            fqdns = ["blue.internal"]
          }
          green = {
            name  = "pool-${module.naming.application_gateway.name}-global-green"
            fqdns = ["green.internal"]
          }
        }
        routing_rule = {
          name      = "rule-${module.naming.application_gateway.name}-global"
          rule_type = "PathBasedRouting"
          priority  = 100
          url_path_map = {
            name                               = "map-${module.naming.application_gateway.name}-global"
            default_backend_address_pool_name  = "pool-${module.naming.application_gateway.name}-global-blue"
            default_backend_http_settings_name = "settings-${module.naming.application_gateway.name}-global-blue"
            default_rewrite_rule_set_name      = "headers-${module.naming.application_gateway.name}-blue"
            path_rules = {
              api = {
                name                       = "rule-${module.naming.application_gateway.name}-global-api"
                paths                      = ["/api/*"]
                backend_address_pool_name  = "pool-${module.naming.application_gateway.name}-global-green"
                backend_http_settings_name = "settings-${module.naming.application_gateway.name}-global-green"
                rewrite_rule_set_name      = "headers-${module.naming.application_gateway.name}-green"
              }
              web = {
                name                       = "rule-${module.naming.application_gateway.name}-global-web"
                paths                      = ["/web/*"]
                backend_address_pool_name  = "pool-${module.naming.application_gateway.name}-global-green"
                backend_http_settings_name = "settings-${module.naming.application_gateway.name}-global-green"
                rewrite_rule_set_name      = "headers-${module.naming.application_gateway.name}-green"
              }
            }
          }
        }
      }
      europe = {
        name                           = "listener-${module.naming.application_gateway.name}-europe"
        frontend_ip_configuration_name = "private-ip-configuration"
        frontend_port_name             = "frontend-port-http"
        protocol                       = "Http"
        host_name                      = "app.company.eu"
        backend_address_pools = {
          blue = {
            name  = "pool-${module.naming.application_gateway.name}-europe-blue"
            fqdns = ["eu-blue.internal"]
          }
          green = {
            name  = "pool-${module.naming.application_gateway.name}-europe-green"
            fqdns = ["eu-green.internal"]
          }
        }
        routing_rule = {
          name      = "rule-${module.naming.application_gateway.name}-europe"
          rule_type = "PathBasedRouting"
          priority  = 110
          url_path_map = {
            name                               = "map-${module.naming.application_gateway.name}-europe"
            default_backend_address_pool_name  = "pool-${module.naming.application_gateway.name}-europe-blue"
            default_backend_http_settings_name = "settings-${module.naming.application_gateway.name}-main"
            default_rewrite_rule_set_name      = "headers-${module.naming.application_gateway.name}-blue"
            path_rules = {
              api = {
                paths                      = ["/api/*"]
                backend_address_pool_name  = "pool-${module.naming.application_gateway.name}-europe-green"
                backend_http_settings_name = "settings-${module.naming.application_gateway.name}-main"
                rewrite_rule_set_name      = "headers-${module.naming.application_gateway.name}-green"
              }
            }
          }
        }
      }
      america = {
        name                           = "listener-${module.naming.application_gateway.name}-america"
        frontend_ip_configuration_name = "private-ip-configuration"
        frontend_port_name             = "frontend-port-http"
        protocol                       = "Http"
        host_name                      = "app.company.usa"
        backend_address_pools = {
          blue = {
            name  = "pool-${module.naming.application_gateway.name}-america-blue"
            fqdns = ["eu-blue.internal"]
          }
          green = {
            name  = "pool-${module.naming.application_gateway.name}-america-green"
            fqdns = ["eu-green.internal"]
          }
        }
        routing_rule = {
          name                       = "rule-${module.naming.application_gateway.name}-america"
          rule_type                  = "Basic"
          priority                   = 130
          backend_http_settings_name = "settings-${module.naming.application_gateway.name}-main"
          backend_address_pool_name  = "pool-${module.naming.application_gateway.name}-america-blue"
        }
      }
      asia = {
        name                           = "listener-${module.naming.application_gateway.name}-asia"
        frontend_ip_configuration_name = "private-ip-configuration"
        frontend_port_name             = "frontend-port-http"
        protocol                       = "Http"
        host_name                      = "app.company.asia"
        backend_address_pools = {
          blue = {
            name  = "pool-${module.naming.application_gateway.name}-asia-blue"
            fqdns = ["eu-blue.internal"]
          }
          green = {
            name  = "pool-${module.naming.application_gateway.name}-asia-green"
            fqdns = ["eu-green.internal"]
          }
        }
        routing_rule = {
          name                        = "rule-${module.naming.application_gateway.name}-asia"
          rule_type                   = "Basic"
          priority                    = 120
          redirect_configuration_name = "redirect-${module.naming.application_gateway.name}-to-global"
        }
      }
      africa = {
        name                           = "listener-${module.naming.application_gateway.name}-africa"
        frontend_ip_configuration_name = "private-ip-configuration"
        frontend_port_name             = "frontend-port-http"
        protocol                       = "Http"
        host_name                      = "app.company.af"
        backend_address_pools = {
          blue = {
            name  = "pool-${module.naming.application_gateway.name}-africa-blue"
            fqdns = ["af-blue.internal"]
          }
          green = {
            name  = "pool-${module.naming.application_gateway.name}-africa-green"
            fqdns = ["af-green.internal"]
          }
        }
        routing_rule = {
          name      = "rule-${module.naming.application_gateway.name}-africa"
          rule_type = "PathBasedRouting"
          priority  = 140
          url_path_map = {
            default_redirect_configuration_name = "redirect-${module.naming.application_gateway.name}-to-url"
            default_rewrite_rule_set_name       = "headers-${module.naming.application_gateway.name}-blue"
            path_rules = {
              api = {
                paths                       = ["/api/*"]
                redirect_configuration_name = "redirect-${module.naming.application_gateway.name}-to-global"
                rewrite_rule_set_name       = "headers-${module.naming.application_gateway.name}-green"
              }
            }
          }
        }
      }
    }
    backend_http_settings = {
      blue = {
        name      = "settings-${module.naming.application_gateway.name}-global-blue"
        port      = 8080
        protocol  = "Https"
        host_name = "blue.internal"
        probe = {
          name                                      = "probe-${module.naming.application_gateway.name}-global-blue"
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
        name      = "settings-${module.naming.application_gateway.name}-global-green"
        port      = 8080
        protocol  = "Https"
        host_name = "green.internal"
        probe = {
          name                                      = "probe-${module.naming.application_gateway.name}-global-green"
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
        name      = "settings-${module.naming.application_gateway.name}-main"
        port      = 8080
        protocol  = "Https"
        host_name = "main.internal"
        probe = {
          name                                      = "probe-${module.naming.application_gateway.name}-main"
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
