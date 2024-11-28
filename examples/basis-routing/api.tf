locals {
  api = {
    listeners = {
      api = {
        name                           = "api-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "api.company.com"
        require_sni                    = false
        certificate = {
          name                = "api-cert"
          key_vault_secret_id = module.kv.certs.api.secret_id
        }
        backend_pools = {
          api = {
            fqdns = ["api.internal"]
            http_settings = {
              main = {
                port      = 8080
                protocol  = "Https"
                host_name = "api.internal"
                probe = {
                  protocol = "Https"
                  path     = "/health"
                  host     = "api.internal"
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
          rule_type = "Basic"
          priority  = 100
          backend_pool    = "api"
          backend_settings = "main"
        }
      }
    }
  }
}


#locals {
  #api = {
    #listeners = {
      #api = {
        #name                           = "api-listener"
        #frontend_ip_configuration_name = "feip-prod-westus-001"
        #frontend_port_name             = "fep-prod-westus-001"
        #protocol                       = "Https"
        #host_name                      = "api.company.com"
        #require_sni                    = false
        #certificate = {
          #name                = "api-cert"
          #key_vault_secret_id = module.kv.certs.api.secret_id
        #}
        #backend_pools = {
          #api = {
            #fqdns = ["api.internal"]
            #http_settings = {
              #main = {
                #port      = 8080
                #protocol  = "Https"
                #host_name = "api.internal"
                #probe = {
                  #protocol = "Https"
                  #path     = "/health"
                  #host     = "api.internal"
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
          #rule_type = "Basic"
          #priority  = 100
          #basic_config = {
            #pool     = "api"
            #settings = "main"
          #}
        #}
      #}
    #}
  #}
#}
