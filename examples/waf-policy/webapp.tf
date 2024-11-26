locals {
  webapp = {
    listeners = {
      global = {
        name                           = "global-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "app.company.com"
        require_sni                    = false
        certificate = {
          name                = "webapp-cert"
          key_vault_secret_id = module.kv.certs.webapp.secret_id
        }
        backend = {
          pools = {
            primary = {
              fqdns = ["app.internal"]
            }
          }
          settings = {
            port      = 8080
            protocol  = "Https"
            host_name = "app.internal"
          }
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
        routing = {
          rule_type = "Basic"
          priority  = 100
        }
      }
    }
  }
}

#locals {
#webapp = {
#listeners = {
#global = {
#name                           = "global-listener"
#frontend_ip_configuration_name = "feip-prod-westus-001"
#frontend_port_name             = "fep-prod-westus-001"
#protocol                       = "Https"
#host_name                      = "app.company.com"
#require_sni                    = false
#certificate = {
#name                = "webapp-cert"
#key_vault_secret_id = module.kv.certs.webapp.secret_id
#}
#}
#},
#backend_address_pools = {
#shared = {
#name         = "app-backend-pool"
#fqdns        = ["app.internal"]
#ip_addresses = []
#}
#},
#backend_http_settings = {
#shared = {
#name       = "app-http-settings"
#port       = 8080
#protocol   = "Https"
#host_name  = "app.internal"
#probe_name = "app-probe"
#}
#},
#probes = {
#shared = {
#name     = "app-probe"
#protocol = "Https"
#path     = "/health"
#host     = "app.internal"
#interval = 30
#timeout  = 30
#match = {
#body        = null
#status_code = ["200-399"]
#}
#}
#},
#request_routing_rules = {
#global = {
#name                       = "global-routing-rule"
#rule_type                  = "Basic"
#http_listener_name         = "global-listener"
#backend_address_pool_name  = "app-backend-pool"
#backend_http_settings_name = "app-http-settings"
#priority                   = 100
#}
#}
#}
#}
