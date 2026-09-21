resource "azurerm_application_gateway" "this" {
  resource_group_name = coalesce(
    var.application_gateway.resource_group_name, var.resource_group_name
  )

  location = coalesce(
    var.application_gateway.location, var.location
  )

  name                              = var.application_gateway.name
  firewall_policy_id                = var.application_gateway.firewall_policy_id
  force_firewall_policy_association = var.application_gateway.force_firewall_policy_association
  fips_enabled                      = var.application_gateway.fips_enabled
  http2_enabled                     = var.application_gateway.http2_enabled
  zones                             = var.application_gateway.zones

  tags = coalesce(
    var.application_gateway.tags, var.tags
  )

  sku {
    name     = var.application_gateway.sku.name
    tier     = var.application_gateway.sku.tier
    capacity = var.application_gateway.sku.capacity
  }

  dynamic "identity" {
    for_each = var.application_gateway.identity != null ? { this = var.application_gateway.identity } : {}

    content {
      type         = var.application_gateway.identity.type
      identity_ids = var.application_gateway.identity.identity_ids
    }
  }

  dynamic "global" {
    for_each = var.application_gateway.global != null ? { this = var.application_gateway.global } : {}

    content {
      request_buffering_enabled  = global.value.request_buffering_enabled
      response_buffering_enabled = global.value.response_buffering_enabled
    }
  }

  dynamic "gateway_ip_configuration" {
    for_each = var.application_gateway.gateway_ip_configurations
    content {
      name      = gateway_ip_configuration.value.name
      subnet_id = gateway_ip_configuration.value.subnet_id
    }
  }

  # Please Note: The AllowApplicationGatewayPrivateLink feature must be registered on the subscription before enabling private link
  dynamic "private_link_configuration" {
    for_each = var.application_gateway.private_link_configuration

    content {
      name = coalesce(
        private_link_configuration.value.name, private_link_configuration.key
      )

      dynamic "ip_configuration" {
        for_each = private_link_configuration.value.ip_configurations

        content {
          subnet_id                     = ip_configuration.value.subnet_id
          primary                       = ip_configuration.value.primary
          private_ip_address            = ip_configuration.value.private_ip_address
          private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
          name = coalesce(
            ip_configuration.value.name, ip_configuration.key
          )
        }
      }
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.application_gateway.frontend_ip_configurations

    content {
      public_ip_address_id            = frontend_ip_configuration.value.public_ip_address_id
      private_ip_address              = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation   = frontend_ip_configuration.value.private_ip_address_allocation
      subnet_id                       = frontend_ip_configuration.value.subnet_id
      private_link_configuration_name = frontend_ip_configuration.value.private_link_configuration_name
      name = coalesce(
        frontend_ip_configuration.value.name, replace("fip-${frontend_ip_configuration.key}", "_", "-")
      )
    }
  }

  dynamic "frontend_port" {
    for_each = var.application_gateway.frontend_ports

    content {
      port = frontend_port.value.port
      name = coalesce(
        frontend_port.value.name, replace("fp-${frontend_port.key}", "_", "-")
      )
    }
  }

  dynamic "ssl_certificate" {
    for_each = distinct(flatten([
      for app_key, app in var.application_gateway.applications : [
        for listener_key, listener in app.listeners :
        {
          name                = listener.certificate.name
          key_vault_secret_id = listener.certificate.key_vault_secret_id
          data                = listener.certificate.data
          password            = listener.certificate.password
    } if listener.certificate != null]]))

    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = [
      for rule_set_key, rule_set in var.application_gateway.rewrite_rule_sets : {
        name = coalesce(
          rule_set.name, replace("rwrs-${rule_set_key}", "_", "-")
        )

        rules = rule_set.rules
      }
    ]

    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rules

        content {
          name = coalesce(
            rewrite_rule.value.name, replace("rwr-${rewrite_rule.key}", "_", "-")
          )

          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = rewrite_rule.value.conditions

            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = rewrite_rule.value.request_header_configurations

            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configurations

            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = rewrite_rule.value.url != null ? { "this" = rewrite_rule.value.url } : {}

            content {
              path         = url.value.path
              query_string = url.value.query_string
              components   = url.value.components
              reroute      = url.value.reroute
            }
          }
        }
      }
    }
  }

  dynamic "backend_address_pool" {
    for_each = flatten([
      for app_key, app in var.application_gateway.applications : [
        for pool_key, pool in app.backend_address_pools : {
          name = coalesce(
            pool.name, replace("bap-${app_key}-${pool_key}", "_", "-")
          )

          ip_addresses = pool.ip_addresses
          fqdns        = pool.fqdns
        }
      ]
    ])

    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = flatten([
      for app_key, app in var.application_gateway.applications : [
        for setting_key, setting in app.backend_http_settings : {
          name = coalesce(
            setting.name, replace("bhs-${app_key}-${setting_key}", "_", "-")
          )

          port                                 = setting.port
          protocol                             = setting.protocol
          host_name                            = setting.host_name
          cookie_based_affinity                = setting.cookie_based_affinity
          request_timeout                      = setting.request_timeout
          path                                 = setting.path
          pick_host_name_from_backend_address  = setting.pick_host_name_from_backend_address
          affinity_cookie_name                 = setting.affinity_cookie_name
          trusted_root_certificate_names       = setting.trusted_root_certificate_names
          connection_draining                  = setting.connection_draining
          dedicated_backend_connection_enabled = setting.dedicated_backend_connection_enabled
          certificate_chain_validation_enabled = setting.certificate_chain_validation_enabled
          sni_name                             = setting.sni_name
          sni_validation_enabled               = setting.sni_validation_enabled

          probe_name = setting.probe != null ? coalesce(
            setting.probe.name, "prb-${app_key}-${setting_key}"
          ) : null
        }
      ]
    ])
    content {
      name                                 = backend_http_settings.value.name
      cookie_based_affinity                = backend_http_settings.value.cookie_based_affinity
      port                                 = backend_http_settings.value.port
      protocol                             = backend_http_settings.value.protocol
      host_name                            = backend_http_settings.value.host_name
      probe_name                           = backend_http_settings.value.probe_name
      request_timeout                      = backend_http_settings.value.request_timeout
      path                                 = backend_http_settings.value.path
      pick_host_name_from_backend_address  = backend_http_settings.value.pick_host_name_from_backend_address
      affinity_cookie_name                 = backend_http_settings.value.affinity_cookie_name
      trusted_root_certificate_names       = backend_http_settings.value.trusted_root_certificate_names
      dedicated_backend_connection_enabled = backend_http_settings.value.dedicated_backend_connection_enabled
      certificate_chain_validation_enabled = backend_http_settings.value.certificate_chain_validation_enabled
      sni_name                             = backend_http_settings.value.sni_name
      sni_validation_enabled               = backend_http_settings.value.sni_validation_enabled

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining != null ? { cd = backend_http_settings.value.connection_draining } : {}

        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  dynamic "backend" {
    for_each = var.application_gateway.backend

    content {
      name = coalesce(
        backend.value.name, backend.key
      )

      port                           = backend.value.port
      protocol                       = backend.value.protocol
      client_ip_preservation_enabled = backend.value.client_ip_preservation_enabled
      host_name                      = backend.value.host_name
      probe_name                     = backend.value.probe_name
      timeout_in_seconds             = backend.value.timeout_in_seconds
      trusted_root_certificate_names = backend.value.trusted_root_certificate_names
    }
  }

  dynamic "probe" {
    for_each = flatten([
      for app_key, app in var.application_gateway.applications : [
        for setting_key, setting in app.backend_http_settings : {
          name = coalesce(
            setting.probe.name, replace("prb-${app_key}-${setting_key}", "_", "-")
          )

          protocol = coalesce(
            setting.probe.protocol, setting.protocol
          )

          path                                      = setting.probe.path
          host                                      = setting.probe.host
          interval                                  = setting.probe.interval
          timeout                                   = setting.probe.timeout
          match_status_codes                        = setting.probe.match != null ? setting.probe.match.status_code : null
          match_body                                = setting.probe.match != null ? setting.probe.match.body : null
          port                                      = setting.probe.port
          minimum_servers                           = setting.probe.minimum_servers
          pick_host_name_from_backend_http_settings = setting.probe.pick_host_name_from_backend_http_settings
          unhealthy_threshold                       = setting.probe.unhealthy_threshold
          proxy_protocol_header_enabled             = setting.probe.proxy_protocol_header_enabled
        } if setting.probe != null
      ]
    ])

    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      port                                      = probe.value.port
      minimum_servers                           = probe.value.minimum_servers
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      proxy_protocol_header_enabled             = probe.value.proxy_protocol_header_enabled

      dynamic "match" {
        for_each = probe.value.match_status_codes != null ? { "this" = probe.value.match_status_codes } : {}
        content {
          status_code = probe.value.match_status_codes
          body        = probe.value.match_body
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = flatten([
      for app_key, app in var.application_gateway.applications : [
        for listener_key, listener in app.listeners : {
          name = coalesce(
            listener.name, replace("lstn-${app_key}-${listener_key}", "_", "-")
          )

          frontend_ip_configuration_name = (
            contains(keys(var.application_gateway.frontend_ip_configurations), listener.frontend_ip_configuration_name)
            ? replace("fip-${listener.frontend_ip_configuration_name}", "_", "-")
            : listener.frontend_ip_configuration_name
          )
          frontend_port_name = (
            contains(keys(var.application_gateway.frontend_ports), listener.frontend_port_name)
            ? replace("fp-${listener.frontend_port_name}", "_", "-")
            : listener.frontend_port_name
          )

          protocol             = listener.protocol
          host_name            = listener.host_name
          require_sni          = listener.require_sni
          ssl_certificate_name = listener.certificate != null ? listener.certificate.name : null
          host_names           = listener.host_names
          ssl_profile_name     = listener.ssl_profile_name
          firewall_policy_id   = listener.firewall_policy_id
          custom_errors        = listener.custom_error_configuration
        }
      ]
    ])

    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      host_names                     = http_listener.value.host_names
      ssl_profile_name               = http_listener.value.ssl_profile_name
      firewall_policy_id             = http_listener.value.firewall_policy_id

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_errors

        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }
    }
  }

  dynamic "listener" {
    for_each = var.application_gateway.listener

    content {
      name = coalesce(
        listener.value.name, listener.key
      )

      frontend_ip_configuration_name = listener.value.frontend_ip_configuration_name
      frontend_port_name             = listener.value.frontend_port_name
      protocol                       = listener.value.protocol
      host_names                     = listener.value.host_names
      ssl_certificate_name           = listener.value.ssl_certificate_name
      ssl_profile_name               = listener.value.ssl_profile_name
    }
  }

  dynamic "url_path_map" {
    for_each = merge(flatten([
      for app_key, app in var.application_gateway.applications : [
        for listener_key, listener in app.listeners : [
          for upm in [listener.routing_rule.url_path_map] : {
            "${app_key}-${listener_key}" = {
              name             = coalesce(upm.name, replace("upm-${app_key}-${listener_key}", "_", "-"))
              backend_pools    = app.backend_address_pools
              backend_settings = app.backend_http_settings
              path_rules       = upm.path_rules
              app_key          = app_key
              listener_key     = listener_key

              default_backend_address_pool_name = (
                upm.default_backend_address_pool_name != null
                ? contains(keys(app.backend_address_pools), upm.default_backend_address_pool_name)
                ? replace("bap-${app_key}-${upm.default_backend_address_pool_name}", "_", "-")
                : upm.default_backend_address_pool_name
                : null
              )

              default_backend_http_settings_name = (
                upm.default_backend_http_settings_name != null
                ? contains(keys(app.backend_http_settings), upm.default_backend_http_settings_name)
                ? replace("bhs-${app_key}-${upm.default_backend_http_settings_name}", "_", "-")
                : upm.default_backend_http_settings_name
                : null
              )

              default_rewrite_rule_set_name = (
                upm.default_rewrite_rule_set_name != null
                ? contains(keys(var.application_gateway.rewrite_rule_sets), upm.default_rewrite_rule_set_name)
                ? replace("rwrs-${upm.default_rewrite_rule_set_name}", "_", "-")
                : upm.default_rewrite_rule_set_name
                : null
              )

              default_redirect_configuration_name = (
                upm.default_redirect_configuration_name != null
                ? contains(keys(var.application_gateway.redirect_configurations), upm.default_redirect_configuration_name)
                ? replace("rdc-${upm.default_redirect_configuration_name}", "_", "-")
                : upm.default_redirect_configuration_name
                : null
              )
            }
          }
        ] if listener.routing_rule.rule_type == "PathBasedRouting"
      ]
    ])...)

    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules

        content {
          name  = coalesce(path_rule.value.name, path_rule.key)
          paths = path_rule.value.paths
          backend_address_pool_name = (
            path_rule.value.backend_address_pool_name != null
            ? contains(keys(url_path_map.value.backend_pools), path_rule.value.backend_address_pool_name)
            ? replace("bap-${url_path_map.value.app_key}-${path_rule.value.backend_address_pool_name}", "_", "-")
            : path_rule.value.backend_address_pool_name
            : null
          )

          backend_http_settings_name = (
            path_rule.value.backend_http_settings_name != null
            ? contains(keys(url_path_map.value.backend_settings), path_rule.value.backend_http_settings_name)
            ? replace("bhs-${url_path_map.value.app_key}-${path_rule.value.backend_http_settings_name}", "_", "-")
            : path_rule.value.backend_http_settings_name
            : null
          )

          rewrite_rule_set_name = (
            path_rule.value.rewrite_rule_set_name != null
            ? contains(keys(var.application_gateway.rewrite_rule_sets), path_rule.value.rewrite_rule_set_name)
            ? replace("rwrs-${path_rule.value.rewrite_rule_set_name}", "_", "-")
            : path_rule.value.rewrite_rule_set_name
            : null
          )

          redirect_configuration_name = (
            path_rule.value.redirect_configuration_name != null
            ? contains(keys(var.application_gateway.redirect_configurations), path_rule.value.redirect_configuration_name)
            ? replace("rdc-${path_rule.value.redirect_configuration_name}", "_", "-")
            : path_rule.value.redirect_configuration_name
            : null
          )

          firewall_policy_id = path_rule.value.firewall_policy_id
        }
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = flatten([
      for app_key, app in var.application_gateway.applications : [
        for redirect_key, redirect in var.application_gateway.redirect_configurations : {
          name          = coalesce(redirect.name, replace("rdc-${redirect_key}", "_", "-"))
          redirect_type = redirect.redirect_type

          target_listener_name = (
            redirect.target_listener != null
            ? contains(keys(app.listeners), redirect.target_listener)
            ? replace("lstn-${app_key}-${redirect.target_listener}", "_", "-")
            : redirect.target_listener
            : null
          )
          target_url           = redirect.target_url
          include_path         = redirect.include_path
          include_query_string = redirect.include_query_string
        }
      ]
    ])
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }

  dynamic "request_routing_rule" {
    for_each = flatten([
      for app_key, app in var.application_gateway.applications : [
        for listener_key, listener in app.listeners : [
          for rule in [listener.routing_rule] : {
            name               = coalesce(rule.name, replace("rrr-${app_key}-${listener_key}", "_", "-"))
            http_listener_name = coalesce(listener.name, replace("lstn-${app_key}-${listener_key}", "_", "-"))
            rule_type          = rule.rule_type
            priority           = rule.priority

            backend_address_pool_name = (
              rule.rule_type == "Basic" && rule.backend_address_pool_name != null
              ? contains(keys(app.backend_address_pools), rule.backend_address_pool_name)
              ? replace("bap-${app_key}-${rule.backend_address_pool_name}", "_", "-")
              : rule.backend_address_pool_name
              : null
            )

            backend_http_settings_name = (
              rule.rule_type == "Basic" && rule.backend_http_settings_name != null
              ? contains(keys(app.backend_http_settings), rule.backend_http_settings_name)
              ? replace("bhs-${app_key}-${rule.backend_http_settings_name}", "_", "-")
              : rule.backend_http_settings_name
              : null
            )

            url_path_map_name = (
              rule.rule_type == "PathBasedRouting"
              ? coalesce(rule.url_path_map == null ? null : rule.url_path_map.name, replace("upm-${app_key}-${listener_key}", "_", "-"))
              : null
            )

            redirect_configuration_name = (
              rule.rule_type == "Basic" && rule.redirect_configuration_name != null
              ? contains(keys(var.application_gateway.redirect_configurations), rule.redirect_configuration_name)
              ? replace("rdc-${rule.redirect_configuration_name}", "_", "-")
              : rule.redirect_configuration_name
              : null
            )

            rewrite_rule_set_name = (
              rule.rewrite_rule_set_name != null
              ? contains(keys(var.application_gateway.rewrite_rule_sets), rule.rewrite_rule_set_name)
              ? replace("rwrs-${rule.rewrite_rule_set_name}", "_", "-")
              : rule.rewrite_rule_set_name
              : null
            )
          }
        ]
      ]
    ])

    content {
      name                        = request_routing_rule.value.name
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      priority                    = request_routing_rule.value.priority
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
    }
  }

  dynamic "routing_rule" {
    for_each = var.application_gateway.routing_rule

    content {
      name = coalesce(
        routing_rule.value.name, routing_rule.key
      )

      backend_address_pool_name = routing_rule.value.backend_address_pool_name
      backend_name              = routing_rule.value.backend_name
      listener_name             = routing_rule.value.listener_name
      priority                  = routing_rule.value.priority
    }
  }

  dynamic "autoscale_configuration" {
    for_each = var.application_gateway.autoscale_configuration != null ? { this = var.application_gateway.autoscale_configuration } : {}

    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  dynamic "ssl_policy" {
    for_each = var.application_gateway.ssl_policy != null ? { this = var.application_gateway.ssl_policy } : {}

    content {
      policy_type          = ssl_policy.value.policy_type
      policy_name          = ssl_policy.value.policy_name
      cipher_suites        = ssl_policy.value.cipher_suites
      disabled_protocols   = ssl_policy.value.disabled_protocols
      min_protocol_version = ssl_policy.value.min_protocol_version
    }
  }

  dynamic "ssl_profile" {
    for_each = var.application_gateway.ssl_profile

    content {
      name                                 = ssl_profile.value.name
      trusted_client_certificate_names     = ssl_profile.value.trusted_client_certificate_names
      verify_client_certificate_issuer_dn  = coalesce(ssl_profile.value.verify_client_certificate_issuer_dn, ssl_profile.value.verify_client_cert_issuer_dn)
      verify_client_certificate_revocation = ssl_profile.value.verify_client_certificate_revocation

      dynamic "ssl_policy" {
        for_each = ssl_profile.value.ssl_policy != null ? { this = ssl_profile.value.ssl_policy } : {}

        content {
          policy_type          = ssl_policy.value.policy_type
          policy_name          = ssl_policy.value.policy_name
          cipher_suites        = ssl_policy.value.cipher_suites
          disabled_protocols   = ssl_policy.value.disabled_protocols
          min_protocol_version = ssl_policy.value.min_protocol_version
        }
      }
    }
  }

  dynamic "waf_configuration" {
    for_each = var.application_gateway.waf_configuration != null ? { this = var.application_gateway.waf_configuration } : {}

    content {
      enabled                  = waf_configuration.value.enabled
      firewall_mode            = waf_configuration.value.firewall_mode
      rule_set_type            = waf_configuration.value.rule_set_type
      rule_set_version         = waf_configuration.value.rule_set_version
      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb
      request_body_check       = waf_configuration.value.request_body_check

      dynamic "disabled_rule_group" {
        for_each = waf_configuration.value.disabled_rule_groups

        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = disabled_rule_group.value.rules
        }
      }

      dynamic "exclusion" {
        for_each = waf_configuration.value.exclusion

        content {
          match_variable          = exclusion.value.match_variable
          selector_match_operator = exclusion.value.selector_match_operator
          selector                = exclusion.value.selector
        }
      }
    }
  }

  dynamic "custom_error_configuration" {
    for_each = var.application_gateway.custom_error_configuration

    content {
      custom_error_page_url = custom_error_configuration.value.custom_error_page_url
      status_code           = custom_error_configuration.value.status_code
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.application_gateway.trusted_root_certificate

    content {
      name                = trusted_root_certificate.value.name
      data                = trusted_root_certificate.value.data
      key_vault_secret_id = trusted_root_certificate.value.key_vault_secret_id
    }
  }

  dynamic "trusted_client_certificate" {
    for_each = var.application_gateway.trusted_client_certificate

    content {
      name = trusted_client_certificate.value.name
      data = trusted_client_certificate.value.data
    }
  }

  depends_on = [azurerm_role_assignment.this]

  lifecycle {
    create_before_destroy = true
  }
}

# role assignment
resource "azurerm_role_assignment" "this" {
  for_each = var.application_gateway.role_assignments

  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_name                   = each.value.role_definition_name
  role_definition_id                     = each.value.role_definition_id
  principal_id                           = each.value.principal_id
  principal_type                         = each.value.principal_type
  description                            = each.value.description
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

# associate virtual machine interfaces
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
  for_each = {
    for assoc in flatten([
      for app_key, app in var.application_gateway.applications : [
        for pool_key, pool in app.backend_address_pools : [
          for vm_key, vm in pool.network_interfaces : {
            key                   = "${pool_key}-${vm_key}"
            network_interface_id  = vm.network_interface_id
            ip_configuration_name = vm.ip_configuration_name
            pool_name = coalesce(
              pool.name, replace("bap-${app_key}-${pool_key}", "_", "-")
            )
          }
        ]
      ]
    ]) : assoc.key => assoc
  }

  network_interface_id  = each.value.network_interface_id
  ip_configuration_name = each.value.ip_configuration_name
  backend_address_pool_id = [
    for pool in azurerm_application_gateway.this.backend_address_pool : pool.id
    if pool.name == each.value.pool_name
  ][0]
}
