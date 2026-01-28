# Application Gateway

This Terraform module simplifies the deployment and management of azure application gateways, offering flexible listener, routing, and backend configurations for secure and efficient traffic handling.

## Features

Utilization of terratest for robust validation.

Supports multiple backend pools with flexible configurations.

Allows multiple frontend IP configurations and ports.

Supports multiple listeners per application with flexible routing rules.

Integrates multiple backend HTTP settings with probes.

Supports path based and basic routing rules.

Allows URL rewrite rules and custom header modifications.

Configures ssl certificates from key vault.

Supports autoscaling and zone redundancy.

Seamlessly associates virtual machine network interfaces with backend address pools for traffic routing.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_application_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_network_interface_application_gateway_backend_address_pool_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_gateway_backend_address_pool_association) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: contains all application gateway configuration

Type:

```hcl
object({
    name                                   = string
    resource_group_name                    = optional(string)
    location                               = optional(string)
    scope                                  = optional(string)
    firewall_policy_id                     = optional(string)
    force_firewall_policy_association      = optional(bool, false)
    fips_enabled                           = optional(bool, false)
    enable_http2                           = optional(bool, false)
    zones                                  = optional(list(string), [])
    tags                                   = optional(map(string))
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
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_location"></a> [location](#input\_location)

Description: default azure region to be used.

Type: `string`

Default: `null`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: default resource group to be used.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: tags to be added to the resources

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_config"></a> [config](#output\_config)

Description: contains application gateway configuration
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md). <br><br>

<a href="https://github.com/cloudnationhq/terraform-azure-agw/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudnationhq/terraform-azure-agw" />
</a>

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/en-us/azure/load-balancer/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/load-balancer/)
- [Rest Api Specs](https://github.com/hashicorp/pandora/tree/main/api-definitions/resource-manager/Network/2024-07-01/ApplicationGateways)
