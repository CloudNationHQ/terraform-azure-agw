locals {
  rewrite_rule_sets = {
    security = {
      rules = {
        security_headers = {
          rule_sequence = 100
          conditions = {
            not_internal_request = {
              variable = "http_req_X-Internal-Request"
              pattern  = "true"
              negate   = true
            }
            public_endpoint = {
              variable    = "var_uri_path"
              pattern     = "^/(api|public)/.*"
              ignore_case = true
            }
            not_health_check = {
              variable = "var_uri_path"
              pattern  = "^/health$"
              negate   = true
            }
            production_traffic = {
              variable    = "var_host"
              pattern     = "^(api|www)[.]company[.]com$"
              ignore_case = true
            }
          }
          response_header_configurations = {
            security_policy = {
              header_name  = "Content-Security-Policy"
              header_value = "default-src 'self' *.company.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' *.google-analytics.com; style-src 'self' 'unsafe-inline' *.googleapis.com;"
            }
            frame_options = {
              header_name  = "X-Frame-Options"
              header_value = "SAMEORIGIN"
            }
            hsts = {
              header_name  = "Strict-Transport-Security"
              header_value = "max-age=31536000; includeSubDomains"
            }
            content_options = {
              header_name  = "X-Content-Type-Options"
              header_value = "nosniff"
            }
            xss_protection = {
              header_name  = "X-XSS-Protection"
              header_value = "1; mode=block"
            }
          }
        }
        cors_headers = {
          rule_sequence = 200
          conditions = {
            allowed_origin = {
              variable    = "http_req_Origin"
              pattern     = "^https://([a-z0-9]+[.])*company[.]com$"
              ignore_case = true
            }
          }
          response_header_configurations = {
            allow_origin = {
              header_name  = "Access-Control-Allow-Origin"
              header_value = "{http_req_Origin}"
            }
            allow_methods = {
              header_name  = "Access-Control-Allow-Methods"
              header_value = "GET POST PUT DELETE OPTIONS"
            }
            allow_headers = {
              header_name  = "Access-Control-Allow-Headers"
              header_value = "Authorization Content-Type X-Request-ID"
            }
            expose_headers = {
              header_name  = "Access-Control-Expose-Headers"
              header_value = "X-Request-ID"
            }
            max_age = {
              header_name  = "Access-Control-Max-Age"
              header_value = "3600"
            }
          }
        }
      }
    }
    api = {
      rules = {
        api_version = {
          rule_sequence = 300
          conditions = {
            version_header = {
              variable = "http_req_Accept-Version"
              pattern  = "2\\.0"
            }
          }
          request_header_configurations = {
            api_version = {
              header_name  = "X-API-Version"
              header_value = "2.0"
            }
          }
        }
        env_specific = {
          rule_sequence = 400
          conditions = {
            dev_environment = {
              variable    = "var_host"
              pattern     = "dev[.]company[.]com$"
              ignore_case = true
            }
          }
          request_header_configurations = {
            env = {
              header_name  = "X-Environment"
              header_value = "development"
            }
            debug = {
              header_name  = "X-Debug-Mode"
              header_value = "enabled"
            }
          }
          response_header_configurations = {
            cache_control = {
              header_name  = "Cache-Control"
              header_value = "no-store no-cache"
            }
          }
        }
        mobile_app = {
          rule_sequence = 500
          conditions = {
            user_agent = {
              variable = "http_req_User-Agent"
              pattern  = "CompanyApp/.*"
            }
          }
          request_header_configurations = {
            client = {
              header_name  = "X-Client-Type"
              header_value = "mobile"
            }
          }
          response_header_configurations = {
            api_version = {
              header_name  = "X-Min-App-Version"
              header_value = "2.1.0"
            }
          }
        }
        legacy_urls = {
          rule_sequence = 600
          conditions = {
            old_path = {
              variable    = "var_uri_path"
              pattern     = "^/legacy/api/v1/(.*)"
              ignore_case = true
            }
          }
          request_header_configurations = {
            original_url = {
              header_name  = "X-Original-URL"
              header_value = "{var_uri_path}"
            }
          }
        }
      }
    }
  }

  portal = {
    listeners = {
      main = {
        name                           = "main-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "portal.company.com"
        require_sni                    = false
        certificate = {
          name                = "portal-cert"
          key_vault_secret_id = module.kv.certs.portal.secret_id
        }
        routing_rule = {
          rule_type             = "PathBasedRouting"
          priority              = 100
          rewrite_rule_set_name = "security"
          url_path_map = {
            default_backend_address_pool_name  = "blue"
            default_backend_http_settings_name = "main"
            default_rewrite_rule_set_name      = "security"
            path_rules = {
              api = {
                paths                      = ["/api/*"]
                backend_address_pool_name  = "blue"
                backend_http_settings_name = "main"
                rewrite_rule_set_name      = "api"
              }
            }
          }
        }
      }
    }
    backend_address_pools = {
      blue = {
        fqdns = ["portal-blue.internal"]
      }
    }
    backend_http_settings = {
      main = {
        port                  = 8080
        protocol              = "Https"
        host_name             = "portal-blue.internal"
        override_backend_path = false
        probe = {
          path     = "/health"
          host     = "portal-blue.internal"
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
