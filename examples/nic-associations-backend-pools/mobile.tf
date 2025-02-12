locals {
  mobile = {
    listeners = {
      mobile = {
        name                           = "mobile-listener"
        frontend_ip_configuration_name = "feip-prod-westus-001"
        frontend_port_name             = "fep-prod-westus-001"
        protocol                       = "Https"
        host_name                      = "mobile.company.com"
        require_sni                    = true

        certificate = {
          name                = "mobile-cert"
          key_vault_secret_id = module.kv.certs.mobile.secret_id
        }

        backend_http_settings = {
          main = {
            port      = 443
            protocol  = "Https"
            host_name = "mobile.internal"
            probe = {
              protocol = "Https"
              path     = "/health"
              host     = "mobile.internal"
              interval = 30
              timeout  = 30
              match = {
                status_code = ["200-399"]
              }
            }
          }
        }

        backend_address_pools = {
          mobile = {
            name  = "bap-mobile"
            fqdns = ["mobile.internal"]
            network_interfaces = {
              vm1 = {
                network_interface_id  = module.vms.vm1.network_interfaces.int1.id
                ip_configuration_name = module.vms.vm1.network_interfaces.int1.ip_configuration[0].name
              }
              vm2 = {
                network_interface_id  = module.vms.vm2.network_interfaces.int1.id
                ip_configuration_name = module.vms.vm2.network_interfaces.int1.ip_configuration[0].name
              }
            }
          }
        }

        routing_rule = {
          rule_type                  = "Basic"
          priority                   = 100
          backend_address_pool_name  = "bap-mobile"
          backend_http_settings_name = "main"
        }
      }
    }
  }
}
