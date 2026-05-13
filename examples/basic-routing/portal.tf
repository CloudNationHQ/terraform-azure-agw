locals {
  # portal = {
  #   listeners = {
  #     portal = {
  #       name                           = "portal-listener"
  #       frontend_ip_configuration_name = "feip-prod-westus-001"
  #       frontend_port_name             = "fep-prod-westus-001"
  #       protocol                       = "Https"
  #       host_name                      = "portal.company.com"
  #       require_sni                    = false
  #       certificate = {
  #         name                = "portal-cert"
  #         key_vault_secret_id = module.kv.certs.portal.secret_id
  #       }
  #       routing_rule = {
  #         rule_type                  = "Basic"
  #         priority                   = 110
  #         backend_address_pool_name  = "portal"
  #         backend_http_settings_name = "main"
  #       }
  #     }
  #   }
  #   backend_address_pools = {
  #     portal = {
  #       fqdns = ["portal2.internal"]
  #     }
  #   }
  #   backend_http_settings = {
  #     main = {
  #       port      = 8443
  #       protocol  = "Https"
  #       host_name = "portal.internal"
  #       probe = {
  #         protocol = "Https"
  #         path     = "/health"
  #         host     = "portal.internal"
  #         interval = 30
  #         timeout  = 30
  #         match = {
  #           body        = null
  #           status_code = ["200-399"]
  #         }
  #       }
  #     }
  #   }
  # }
}
