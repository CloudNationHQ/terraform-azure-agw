variable "config" {
  description = "contains all application gateway configuration"
  type = object({
    name                              = string
    resource_group_name               = optional(string)
    location                          = optional(string)
    scope                             = optional(string)
    firewall_policy_id                = optional(string)
    force_firewall_policy_association = optional(bool, false)
    fips_enabled                      = optional(bool, false)
    enable_http2                      = optional(bool, false)
    zones                             = optional(list(string), [])
    tags                              = optional(map(string))
    sku = object({
      name     = string
      tier     = string
      capacity = optional(number)
    })
    identity = optional(object({
      type         = optional(string, "UserAssigned")
      identity_ids = list(string)
    }))
    role_assignment = optional(object({
      name                                   = optional(string)
      scope                                  = string
      role_definition_id                     = optional(string)
      principal_id                           = string
      principal_type                         = optional(string)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      skip_service_principal_aad_check       = optional(bool)
    }))
    global = optional(object({
      request_buffering_enabled  = bool
      response_buffering_enabled = bool
    }))
    gateway_ip_configurations = map(object({
      name      = string
      subnet_id = string
    }))
    private_link_configuration = optional(map(object({
      name = optional(string)
      ip_configurations = map(object({
        name                          = optional(string)
        subnet_id                     = string
        primary                       = optional(bool, false)
        private_ip_address            = optional(string)
        private_ip_address_allocation = optional(string, "Dynamic")
      }))
    })), {})
    frontend_ip_configurations = map(object({
      name                            = optional(string)
      public_ip_address_id            = optional(string)
      private_ip_address              = optional(string)
      private_ip_address_allocation   = optional(string, "Dynamic")
      subnet_id                       = optional(string)
      private_link_configuration_name = optional(string)
    }))
    frontend_ports = map(object({
      name = optional(string)
      port = number
    }))
    applications = map(object({
      listeners = map(object({
        name                           = optional(string)
        frontend_ip_configuration_name = string
        frontend_port_name             = string
        protocol                       = string
        host_name                      = optional(string)
        require_sni                    = optional(bool, false)
        host_names                     = optional(list(string), [])
        ssl_profile_name               = optional(string)
        firewall_policy_id             = optional(string)
        certificate = optional(object({
          name                = string
          key_vault_secret_id = optional(string)
          data                = optional(string)
          password            = optional(string)
        }))
        custom_error_configuration = optional(list(object({
          status_code           = string
          custom_error_page_url = string
        })), [])
        routing_rule = object({
          name                        = optional(string)
          rule_type                   = string
          priority                    = number
          backend_address_pool_name   = optional(string)
          backend_http_settings_name  = optional(string)
          redirect_configuration_name = optional(string)
          rewrite_rule_set_name       = optional(string)
          url_path_map = optional(object({
            name                                = optional(string)
            default_backend_address_pool_name   = optional(string)
            default_backend_http_settings_name  = optional(string)
            default_rewrite_rule_set_name       = optional(string)
            default_redirect_configuration_name = optional(string)
            path_rules = map(object({
              name                        = optional(string)
              paths                       = list(string)
              backend_address_pool_name   = optional(string)
              backend_http_settings_name  = optional(string)
              rewrite_rule_set_name       = optional(string)
              redirect_configuration_name = optional(string)
              firewall_policy_id          = optional(string)
            }))
          }))
        })
      }))
      backend_address_pools = optional(map(object({
        name         = optional(string)
        fqdns        = optional(list(string), [])
        ip_addresses = optional(list(string), [])
        network_interfaces = optional(map(object({
          network_interface_id  = string
          ip_configuration_name = string
        })), {})
      })), {})
      backend_http_settings = optional(map(object({
        name                                 = optional(string)
        port                                 = number
        protocol                             = string
        host_name                            = optional(string)
        cookie_based_affinity                = optional(string, "Disabled")
        request_timeout                      = optional(number, 30)
        path                                 = optional(string, "/")
        pick_host_name_from_backend_address  = optional(bool, false)
        affinity_cookie_name                 = optional(string)
        trusted_root_certificate_names       = optional(list(string), [])
        dedicated_backend_connection_enabled = optional(bool)
        connection_draining = optional(object({
          enabled           = bool
          drain_timeout_sec = number
        }))
        authentication_certificate = optional(map(object({
          name = string
        })), {})
        probe = optional(object({
          name                                      = optional(string)
          protocol                                  = optional(string)
          path                                      = string
          host                                      = optional(string)
          port                                      = optional(number)
          interval                                  = number
          timeout                                   = number
          minimum_servers                           = optional(number)
          unhealthy_threshold                       = optional(number, 3)
          pick_host_name_from_backend_http_settings = optional(bool, false)
          match = optional(object({
            status_code = list(string)
            body        = optional(string)
          }))
        }))
      })), {})
    }))
    rewrite_rule_sets = optional(map(object({
      name = optional(string)
      rules = map(object({
        name          = optional(string)
        rule_sequence = number
        conditions = optional(map(object({
          variable    = string
          pattern     = string
          ignore_case = optional(bool)
          negate      = optional(bool)
        })), {})
        request_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })), {})
        response_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })), {})
        url = optional(object({
          path         = optional(string)
          query_string = optional(string)
          components   = optional(string)
          reroute      = optional(bool, false)
        }))
      }))
    })), {})
    redirect_configurations = optional(map(object({
      name                 = optional(string)
      redirect_type        = string
      target_listener      = optional(string)
      target_url           = optional(string)
      include_path         = optional(bool, false)
      include_query_string = optional(bool, false)
    })), {})
    autoscale_configuration = optional(object({
      min_capacity = number
      max_capacity = optional(number)
    }))
    ssl_policy = optional(object({
      policy_type          = optional(string, "Predefined")
      policy_name          = optional(string)
      cipher_suites        = optional(list(string))
      disabled_protocols   = optional(list(string))
      min_protocol_version = optional(string)
    }))
    ssl_profile = optional(map(object({
      name                                 = string
      trusted_client_certificate_names     = list(string)
      verify_client_cert_issuer_dn         = optional(bool, false)
      verify_client_certificate_revocation = optional(string)
      ssl_policy = optional(object({
        policy_type          = optional(string, "Predefined")
        policy_name          = optional(string)
        cipher_suites        = optional(list(string))
        disabled_protocols   = optional(list(string))
        min_protocol_version = optional(string, "TLSv1_2")
      }))
    })), {})
    waf_configuration = optional(object({
      enabled                  = optional(bool, true)
      firewall_mode            = optional(string, "Prevention")
      rule_set_type            = optional(string, "OWASP")
      rule_set_version         = optional(string, "3.2")
      file_upload_limit_mb     = optional(number, 100)
      max_request_body_size_kb = optional(number, 128)
      request_body_check       = optional(bool, true)
      disabled_rule_groups = optional(map(object({
        rule_group_name = string
        rules           = optional(list(number), [])
      })), {})
      exclusion = optional(map(object({
        match_variable          = string
        selector_match_operator = optional(string)
        selector                = optional(string)
      })), {})
    }))
    custom_error_configuration = optional(map(object({
      status_code           = string
      custom_error_page_url = string
    })), {})
    authentication_certificate = optional(map(object({
      name = string
      data = string
    })), {})
    trusted_root_certificate = optional(map(object({
      name                = string
      data                = optional(string)
      key_vault_secret_id = optional(string)
    })), {})
    trusted_client_certificate = optional(map(object({
      name = string
      data = string
    })), {})
  })

  validation {
    condition     = var.config.location != null || var.location != null
    error_message = "location must be provided either in the config object or as a separate variable."
  }

  validation {
    condition     = var.config.resource_group_name != null || var.resource_group_name != null
    error_message = "resource_group_name must be provided either in the config object or as a separate variable."
  }
}

variable "location" {
  description = "default azure region to be used."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "default resource group to be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
