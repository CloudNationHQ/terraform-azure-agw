locals {
  catalyst = {
    rewrite_rule_sets = {
      headers = {
        rules = {
          add_custom_request_header = {
            rule_sequence = 100
            conditions    = {}
            request_header_configurations = {
              header1 = {
                header_name  = "X-Custom-Header"
                header_value = "CustomValue"
              }
            }
            response_header_configurations = {
              header1 = {
                header_name  = "X-Response-Custom"
                header_value = "ResponseValue"
              }
            }
          }
        }
      }
      headers2 = {
        rules = {
          add_custom_request_header2 = {
            rule_sequence = 100
            conditions    = {}
            request_header_configurations = {
              header2 = {
                header_name  = "X-Custom-Header"
                header_value = "CustomValue"
              }
            }
            response_header_configurations = {
              header2 = {
                header_name  = "X-Response-Custom"
                header_value = "ResponseValue"
              }
            }
          }
        }
      }
    },
    listeners = {
      global = {
        name                           = "global-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "app.company.com"
        require_sni                    = false
        certificate = {
          name                = "global-cert"
          key_vault_secret_id = module.kv.certs.global.secret_id
        }
        backend_pools = {
          blue = {
            fqdns = ["blue.internal"]
            http_settings = {
              main = {
                port      = 8080
                protocol  = "Https"
                host_name = "blue.internal"
                probe = {
                  protocol = "Https"
                  path     = "/health"
                  host     = "blue.internal"
                  interval = 30
                  timeout  = 30
                  match = {
                    body        = null
                    status_code = ["200-399"]
                  }
                }
              }
            }
          },
          green = {
            fqdns = ["green.internal"]
            http_settings = {
              main = {
                port      = 8080
                protocol  = "Https"
                host_name = "green.internal"
                probe = {
                  protocol = "Https"
                  path     = "/health"
                  host     = "green.internal"
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
          rule_type             = "PathBasedRouting"
          priority              = 100
          rewrite_rule_set_name = "headers"
          url_path_map = {
            default_pool                  = "blue"
            default_settings              = "main"
            default_rewrite_rule_set_name = "headers"
            path_rules = {
              api = {
                paths                 = ["/api/*"]
                pool                  = "green"
                settings              = "main"
                rewrite_rule_set_name = "headers"
              },
              web = {
                paths                 = ["/web/*"]
                pool                  = "green"
                settings              = "main"
                rewrite_rule_set_name = "headers"
              }
            }
          }
        }
      },
      europe = {
        name                           = "europe-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "app.company.eu"
        require_sni                    = false
        certificate = {
          name                = "europe-cert"
          key_vault_secret_id = module.kv.certs.europe.secret_id
        }
        backend_pools = {
          blue = {
            fqdns = ["eu-blue.internal"]
            http_settings = {
              main = {
                port      = 8080
                protocol  = "Https"
                host_name = "eu-blue.internal"
                probe = {
                  protocol = "Https"
                  path     = "/health"
                  host     = "eu-blue.internal"
                  interval = 30
                  timeout  = 30
                  match = {
                    body        = null
                    status_code = ["200-399"]
                  }
                }
              }
            }
          },
          green = {
            fqdns = ["eu-green.internal"]
            http_settings = {
              main = {
                port      = 8080
                protocol  = "Https"
                host_name = "eu-green.internal"
                probe = {
                  protocol = "Https"
                  path     = "/health"
                  host     = "eu-green.internal"
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
          rule_type             = "PathBasedRouting"
          priority              = 110
          rewrite_rule_set_name = "headers"
          url_path_map = {
            default_pool                  = "blue"
            default_settings              = "main"
            default_rewrite_rule_set_name = "headers"
            path_rules = {
              api = {
                paths                 = ["/api/*"]
                pool                  = "green"
                settings              = "main"
                rewrite_rule_set_name = "headers2"
              }
            }
          }
        }
      }
    }
  }
}

#locals {
#catalyst = {
#listeners = {
#global = {
#name                           = "global-listener"
#frontend_ip_configuration_name = "feip-prod-westus-001"
#frontend_port_name             = "fep-prod-westus-001"
#protocol                       = "Https"
#host_name                      = "app.company.com"
#require_sni                    = false
#certificate = {
#name                = "global-cert"
#key_vault_secret_id = module.kv.certs.global.secret_id
#}
#backend_pools = { // optional maken, redirect kan gaan naar bestaande listener
#blue = {
#fqdns = ["blue.internal"]
#http_settings = {
#main = {
#port      = 8080
#protocol  = "Https"
#host_name = "blue.internal"
#probe = {
#protocol = "Https"
#path     = "/health"
#host     = "blue.internal"
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
#green = {
#fqdns = ["green.internal"]
#http_settings = {
#main = {
#port      = 8080
#protocol  = "Https"
#host_name = "green.internal"
#probe = {
#protocol = "Https"
#path     = "/health"
#host     = "green.internal"
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
#}
#routing = {
#rule_type = "PathBasedRouting"
#priority  = 100
#url_path_map = {
#default_pool     = "blue"
#default_settings = "main"
#path_rules = {
#api = {
#paths    = ["/api/*"]
#pool     = "green"
#settings = "main"
#}
#web = {
#paths    = ["/web/*"]
#pool     = "green"
#settings = "main"
#}
#}
#}
#}
#rewrite_rules = {
#rules = {
#add_custom_request_header = {
#rule_sequence = 100
#conditions    = {}
#request_header_configurations = {
#header1 = {
#header_name  = "X-Custom-Header"
#header_value = "CustomValue"
#}
#}
#response_header_configurations = {
#header1 = {
#header_name  = "X-Response-Custom"
#header_value = "ResponseValue"
#}
#}
#}
#}
#}
#},
#europe = {
#name                           = "europe-listener"
#frontend_ip_configuration_name = "feip-prod-westus-001"
#frontend_port_name             = "fep-prod-westus-001"
#protocol                       = "Https"
#host_name                      = "app.company.eu"
#require_sni                    = false
#certificate = {
#name                = "europe-cert"
#key_vault_secret_id = module.kv.certs.europe.secret_id
#}
#backend_pools = {
#blue = {
#fqdns = ["eu-blue.internal"]
#http_settings = {
#main = {
#port      = 8080
#protocol  = "Https"
#host_name = "eu-blue.internal"
#probe = {
#protocol = "Https"
#path     = "/health"
#host     = "eu-blue.internal"
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
#green = {
#fqdns = ["eu-green.internal"]
#http_settings = {
#main = {
#port      = 8080
#protocol  = "Https"
#host_name = "eu-green.internal"
#probe = {
#protocol = "Https"
#path     = "/health"
#host     = "eu-green.internal"
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
#}
#routing = {
#rule_type = "PathBasedRouting"
#priority  = 110
#url_path_map = {
#default_pool     = "blue"
#default_settings = "main"
#path_rules = {
#api = {
#paths    = ["/api/*"]
#pool     = "green"
#settings = "main"
#}
#}
#}
#}
#rewrite_rules = {
#rules = {
#add_custom_request_header = {
#rule_sequence = 100
#conditions    = {}
#request_header_configurations = {
#header1 = {
#header_name  = "X-Custom-Header"
#header_value = "CustomValue"
#}
#}
#response_header_configurations = {
#header1 = {
#header_name  = "X-Response-Custom"
#header_value = "ResponseValue"
#}
#}
#}
#}
#}
#}
#}
#}
#}
