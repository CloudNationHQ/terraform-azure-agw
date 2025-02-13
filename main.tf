resource "azurerm_application_gateway" "application_gateway" {
  name                              = var.config.name
  resource_group_name               = coalesce(try(var.config.resource_group, null), var.resource_group)
  location                          = coalesce(try(var.config.location, null), var.location)
  firewall_policy_id                = try(var.config.firewall_policy_id, null)
  force_firewall_policy_association = try(var.config.force_firewall_policy_association, false)
  fips_enabled                      = try(var.config.fips_enabled, false)
  enable_http2                      = try(var.config.enable_http2, false)
  zones                             = try(var.config.zones, [])
  tags                              = try(var.config.tags, var.tags, {})

  sku {
    name     = var.config.sku.name
    tier     = var.config.sku.tier
    capacity = var.config.sku.capacity
  }

  dynamic "identity" {
    for_each = try(var.config.identity, null) != null ? { default = var.config.identity } : {}
    content {
      type         = try(var.config.identity.type, "UserAssigned")
      identity_ids = concat([azurerm_user_assigned_identity.application_gateway_identity["uai"].id], try(identity.value.identity_ids, []))
    }
  }

  dynamic "global" {
    for_each = try(var.config.global, null) != null ? { default = var.config.global } : {}
    content {
      request_buffering_enabled  = global.value.request_buffering_enabled
      response_buffering_enabled = global.value.response_buffering_enabled
    }
  }

  dynamic "gateway_ip_configuration" {
    for_each = var.config.gateway_ip_configurations
    content {
      name      = gateway_ip_configuration.value.name
      subnet_id = gateway_ip_configuration.value.subnet_id
    }
  }

  # Please Note: The AllowApplicationGatewayPrivateLink feature must be registered on the subscription before enabling private link
  dynamic "private_link_configuration" {
    for_each = { for key, plc in try(var.config.private_link_configuration, {}) : key => plc }
    content {
      name = try(private_link_configuration.value.name, private_link_configuration.key)
      dynamic "ip_configuration" {
        for_each = { for key, ipc in try(private_link_configuration.value.ip_configurations, {}) : key => ipc }

        content {
          name                          = try(ip_configuration.value.name, ip_configuration.key)
          subnet_id                     = ip_configuration.value.subnet_id
          primary                       = try(ip_configuration.value.primary, false)
          private_ip_address            = try(ip_configuration.value.private_ip_address, null)
          private_ip_address_allocation = try(ip_configuration.value.private_ip_address_allocation, "Dynamic")
        }
      }
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = { for key, fip in var.config.frontend_ip_configurations : key => fip }
    content {
      name                            = try(frontend_ip_configuration.value.name, replace("fip-${frontend_ip_configuration.key}", "_", "-"))
      public_ip_address_id            = try(frontend_ip_configuration.value.public_ip_address_id, null)
      private_ip_address              = try(frontend_ip_configuration.value.private_ip_address, null)
      private_ip_address_allocation   = try(frontend_ip_configuration.value.private_ip_address_allocation, "Dynamic")
      subnet_id                       = try(frontend_ip_configuration.value.subnet_id, null)
      private_link_configuration_name = try(frontend_ip_configuration.value.private_link_configuration_name, null)
    }
  }

  dynamic "frontend_port" {
    for_each = { for key, port in var.config.frontend_ports : key => port }
    content {
      name = try(frontend_port.value.name, replace("fp-${frontend_port.key}", "_", "-"))
      port = frontend_port.value.port
    }
  }

  dynamic "ssl_certificate" {
    for_each = distinct(flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners :
        {
          name                = listener.certificate.name
          key_vault_secret_id = try(listener.certificate.key_vault_secret_id, null)
          data                = try(listener.certificate.data, null)
          password            = try(listener.certificate.password, null)
    } if try(listener.certificate, null) != null]]))

    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = try(ssl_certificate.value.key_vault_secret_id, null)
      data                = try(ssl_certificate.value.data, null)
      password            = try(ssl_certificate.value.password, null)
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = flatten(
      try([
        for rule_set_key, rule_set in var.config.rewrite_rule_sets : {
          name  = try(rule_set.name, replace("rwrs-${rule_set_key}", "_", "-"))
          rules = rule_set.rules
        }
      ], [])
    )

    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rules

        content {
          name          = try(rewrite_rule.value.name, replace("rwr-${rewrite_rule.key}", "_", "-"))
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = try(rewrite_rule.value.conditions, {})

            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = try(condition.value.ignore_case, null)
              negate      = try(condition.value.negate, null)
            }
          }

          dynamic "request_header_configuration" {
            for_each = try(
              rewrite_rule.value.request_header_configurations, {}
            )

            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = try(
              rewrite_rule.value.response_header_configurations, {}
            )

            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }
        }
      }
    }
  }

  dynamic "backend_address_pool" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : [
          for pool_key, pool in try(listener.backend_address_pools, {}) : {
            name  = try(pool.name, replace("bap-${app_key}-${listener_key}-${pool_key}", "_", "-"))
            fqdns = pool.fqdns
          }
        ]
      ]
    ])
    content {
      name         = backend_address_pool.value.name
      fqdns        = try(backend_address_pool.value.fqdns, [])
      ip_addresses = try(backend_address_pool.value.ip_addresses, [])
    }
  }

  dynamic "backend_http_settings" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for setting_key, setting in try(app.backend_http_settings, {}) : {
          name                                = try(setting.name, replace("bhs-${app_key}-${setting_key}", "_", "-"))
          port                                = setting.port
          protocol                            = setting.protocol
          host_name                           = try(setting.host_name, null)
          cookie_based_affinity               = try(setting.cookie_based_affinity, "Disabled")
          request_timeout                     = try(setting.request_timeout, 30)
          probe_name                          = try(setting.probe != null, false) ? try(setting.probe.name, "prb-${app_key}-${setting_key}") : null
          path                                = try(setting.path, "/")
          pick_host_name_from_backend_address = try(setting.pick_host_name_from_backend_address, false)
          affinity_cookie_name                = try(setting.affinity_cookie_name, null)
          trusted_root_certificate_names      = try(setting.trusted_root_certificate_names, [])
        }
      ]
    ])
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      host_name                           = backend_http_settings.value.host_name
      probe_name                          = backend_http_settings.value.probe_name
      request_timeout                     = backend_http_settings.value.request_timeout
      path                                = backend_http_settings.value.path
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "connection_draining" {
        for_each = lookup(backend_http_settings.value, "connection_draining", null) != null ? { cd = backend_http_settings.value.connection_draining } : {}

        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }

      dynamic "authentication_certificate" {
        for_each = lookup(backend_http_settings.value, "authentication_certificate", {})
        content {
          name = authentication_certificate.value.name
        }
      }
    }
  }

  dynamic "probe" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for setting_key, setting in try(app.backend_http_settings, {}) :
        {
          name                                      = try(setting.probe.name, replace("prb-${app_key}-${setting_key}", "_", "-"))
          protocol                                  = try(setting.probe.protocol, setting.protocol)
          path                                      = setting.probe.path
          host                                      = setting.probe.host
          interval                                  = setting.probe.interval
          timeout                                   = setting.probe.timeout
          match_status_codes                        = try(setting.probe.match.status_code, null)
          match_body                                = try(setting.probe.match.body, null)
          port                                      = try(setting.probe.port, null)
          minimum_servers                           = try(setting.probe.minimum_servers, null)
          pick_host_name_from_backend_http_settings = try(setting.probe.pick_host_name_from_backend_http_settings, false)
          unhealthy_threshold                       = try(setting.probe.unhealthy_threshold, 3)
        } if try(setting.probe, null) != null
      ]
      ]
    )

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

      dynamic "match" {
        for_each = try(probe.value.match_status_codes, null) != null ? [1] : []
        content {
          status_code = probe.value.match_status_codes
          body        = probe.value.match_body
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for fip_key, fip in var.config : [
          for listener_key, listener in app.listeners : {
            name = try(listener.name, replace("lstn-${app_key}-${listener_key}", "_", "-"))
            ## contains(keys()) is used to check if the property name (e.g. frontend_port_name), references a key in another map,
            ## if so then that key is derived for naming, if not then the property name is the actual name used for naming
            frontend_ip_configuration_name = contains(keys(var.config.frontend_ip_configurations), listener.frontend_ip_configuration_name
            ) ? replace("fip-${listener.frontend_ip_configuration_name}", "_", "-") : listener.frontend_ip_configuration_name
            frontend_port_name = contains(keys(var.config.frontend_ports), listener.frontend_port_name
            ) ? replace("fp-${listener.frontend_port_name}", "_", "-") : listener.frontend_port_name
            protocol             = listener.protocol
            host_name            = try(listener.host_name, null)
            require_sni          = try(listener.require_sni, false)
            ssl_certificate_name = try(listener.certificate.name, null)
            host_names           = try(listener.host_names, [])
            ssl_profile_name     = try(listener.ssl_profile_name, null)
            firewall_policy_id   = try(listener.firewall_policy_id, null)
          }
      ]]
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
    }
  }

  # url path maps (only when path rules exist)
  dynamic "url_path_map" {
    for_each = merge(flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners :
        # only include if it's PathBasedRouting and has path rules
        try(listener.routing_rule.rule_type, null) == "PathBasedRouting" ? {
          "${app_key}-${listener_key}" = {
            name             = try(listener.routing_rule.url_path_map.name, replace("upm-${app_key}-${listener_key}", "_", "-"))
            backend_pools    = try(listener.backend_address_pools, {})
            backend_settings = try(app.backend_http_settings, {})
            path_rules       = listener.routing_rule.url_path_map.path_rules
            app_key          = app_key
            listener_key     = listener_key

            default_backend_address_pool_name = try(listener.routing_rule.url_path_map.default_backend_address_pool_name, null) != null ? contains(
              keys(listener.backend_address_pools), listener.routing_rule.url_path_map.default_backend_address_pool_name) ? replace(
              "bap-${app_key}-${listener_key}-${listener.routing_rule.url_path_map.default_backend_address_pool_name}", "_", "-"
            ) : listener.routing_rule.url_path_map.default_backend_address_pool_name : null

            default_backend_http_settings_name = try(listener.routing_rule.url_path_map.default_backend_http_settings_name, null) != null ? contains(
              keys(app.backend_http_settings), listener.routing_rule.url_path_map.default_backend_http_settings_name) ? replace(
              "bhs-${app_key}-${listener.routing_rule.url_path_map.default_backend_http_settings_name}", "_", "-"
            ) : listener.routing_rule.url_path_map.default_backend_http_settings_name : null

            default_rewrite_rule_set_name = try(listener.routing_rule.url_path_map.default_rewrite_rule_set_name, null) != null ? contains(
              keys(var.config.rewrite_rule_sets), listener.routing_rule.url_path_map.default_rewrite_rule_set_name) ? replace(
              "rwrs-${listener.routing_rule.url_path_map.default_rewrite_rule_set_name}", "_", "-"
            ) : listener.routing_rule.url_path_map.default_rewrite_rule_set_name : null

            default_redirect_configuration_name = try(listener.routing_rule.url_path_map.default_redirect_configuration_name, null) != null ? contains(
              keys(var.config.redirect_configurations), listener.routing_rule.url_path_map.default_redirect_configuration_name) ? replace(
              "rdc-${listener.routing_rule.url_path_map.default_redirect_configuration_name}", "_", "-"
            ) : listener.routing_rule.url_path_map.default_redirect_configuration_name : null
          }
        } : {}
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
          name  = try(path_rule.value.name, path_rule.key)
          paths = path_rule.value.paths
          backend_address_pool_name = try(path_rule.value.backend_address_pool_name, null) != null ? contains(
            keys(url_path_map.value.backend_pools), path_rule.value.backend_address_pool_name) ? replace(
            "bap-${url_path_map.value.app_key}-${url_path_map.value.listener_key}-${path_rule.value.backend_address_pool_name}", "_", "-"
          ) : path_rule.value.backend_address_pool_name : null

          backend_http_settings_name = try(path_rule.value.backend_http_settings_name, null) != null ? contains(
            keys(url_path_map.value.backend_settings), path_rule.value.backend_http_settings_name) ? replace(
            "bhs-${url_path_map.value.app_key}-${path_rule.value.backend_http_settings_name}", "_", "-"
          ) : path_rule.value.backend_http_settings_name : null

          rewrite_rule_set_name = try(path_rule.value.rewrite_rule_set_name, null) != null ? contains(
            keys(var.config.rewrite_rule_sets), path_rule.value.rewrite_rule_set_name) ? replace(
            "rwrs-${path_rule.value.rewrite_rule_set_name}", "_", "-"
          ) : path_rule.value.rewrite_rule_set_name : null

          redirect_configuration_name = try(path_rule.value.redirect_configuration_name, null) != null ? contains(
            keys(var.config.redirect_configurations), path_rule.value.redirect_configuration_name) ? replace(
            "rdc-${path_rule.value.redirect_configuration_name}", "_", "-"
          ) : path_rule.value.redirect_configuration_name : null

          firewall_policy_id = try(path_rule.value.firewall_policy_id, null)
        }
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for redirect_key, redirect in try(var.config.redirect_configurations, {}) :
        {
          name          = try(redirect.name, replace("rdc-${redirect_key}", "_", "-"))
          redirect_type = redirect.redirect_type
          # handle either target_listener or target_url
          target_listener_name = try(redirect.target_listener, null) != null ? contains(keys(app.listeners
          ), redirect.target_listener) ? replace("lstn-${app_key}-${redirect.target_listener}", "_", "-") : redirect.target_listener : null
          target_url           = try(redirect.target_url, null)
          include_path         = try(redirect.include_path, false)
          include_query_string = try(redirect.include_query_string, false)
        }
      ]
      ]
    )
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
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : [
          {
            name               = try(listener.routing_rule.name, replace("rrr-${app_key}-${listener_key}", "_", "-"))
            http_listener_name = try(listener.name, replace("lstn-${app_key}-${listener_key}", "_", "-"))
            rule_type          = listener.routing_rule.rule_type
            priority           = listener.routing_rule.priority

            backend_address_pool_name = (listener.routing_rule.rule_type == "Basic" && try(listener.routing_rule.backend_address_pool_name, null) != null) ? contains(keys(listener.backend_address_pools
            ), listener.routing_rule.backend_address_pool_name) ? replace("bap-${app_key}-${listener_key}-${listener.routing_rule.backend_address_pool_name}", "_", "-") : listener.routing_rule.backend_address_pool_name : null

            backend_http_settings_name = (listener.routing_rule.rule_type == "Basic" && try(listener.routing_rule.backend_http_settings_name, null) != null) ? contains(keys(app.backend_http_settings
            ), listener.routing_rule.backend_http_settings_name) ? replace("bhs-${app_key}-${listener.routing_rule.backend_http_settings_name}", "_", "-") : listener.routing_rule.backend_http_settings_name : null

            url_path_map_name = listener.routing_rule.rule_type == "PathBasedRouting" ? try(listener.routing_rule.url_path_map.name, replace("upm-${app_key}-${listener_key}", "_", "-")) : null

            redirect_configuration_name = (listener.routing_rule.rule_type == "Basic" && try(listener.routing_rule.redirect_configuration_name, null) != null) ? contains(keys(var.config.redirect_configurations
            ), listener.routing_rule.redirect_configuration_name) ? replace("rdc-${listener.routing_rule.redirect_configuration_name}", "_", "-") : listener.routing_rule.redirect_configuration_name : null

            rewrite_rule_set_name = try(listener.routing_rule.rewrite_rule_set_name, null) != null ? contains(keys(var.config.rewrite_rule_sets
            ), listener.routing_rule.rewrite_rule_set_name) ? replace("rwrs-${listener.routing_rule.rewrite_rule_set_name}", "_", "-") : listener.routing_rule.rewrite_rule_set_name : null
          }
        ]
      ]
      ]
    )
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      priority                    = request_routing_rule.value.priority # keep required
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
    }
  }

  dynamic "autoscale_configuration" {
    for_each = lookup(var.config, "autoscale_configuration", null) != null ? { key = var.config.autoscale_configuration } : {}
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = try(autoscale_configuration.value.max_capacity, null)
    }
  }

  dynamic "ssl_policy" {
    for_each = lookup(var.config, "ssl_policy", null) != null ? { key = var.config.ssl_policy } : {}

    content {
      policy_type          = try(ssl_policy.value.policy_type, "Predefined")
      policy_name          = try(ssl_policy.value.policy_name, null)
      cipher_suites        = try(ssl_policy.value.cipher_suites, null)
      disabled_protocols   = try(ssl_policy.value.disabled_protocols, null)
      min_protocol_version = try(ssl_policy.value.min_protocol_version, "TLSv1_2")
    }
  }

  dynamic "ssl_profile" {
    for_each = lookup(var.config, "ssl_profile", {})

    content {
      name                                 = ssl_profile.value.name
      trusted_client_certificate_names     = ssl_profile.value.trusted_client_certificate_names
      verify_client_cert_issuer_dn         = try(ssl_profile.value.verify_client_cert_issuer_dn, false)
      verify_client_certificate_revocation = try(ssl_profile.value.verify_client_certificate_revocation, null)

      dynamic "ssl_policy" {
        for_each = try(ssl_profile.value.ssl_policy, {}) != null ? { key = ssl_profile.value.ssl_policy } : {}
        content {
          policy_type          = try(ssl_policy.value.policy_type, "Predefined")
          policy_name          = try(ssl_policy.value.policy_name, null)
          cipher_suites        = try(ssl_policy.value.cipher_suites, null)
          disabled_protocols   = try(ssl_policy.value.disabled_protocols, null)
          min_protocol_version = try(ssl_policy.value.min_protocol_version, "TLSv1_2")
        }
      }
    }
  }

  dynamic "waf_configuration" {
    for_each = lookup(var.config, "waf_configuration", null) != null ? { waf = var.config.waf_configuration } : {}

    content {
      enabled                  = try(waf_configuration.value.enabled, true)
      firewall_mode            = try(waf_configuration.value.firewall_mode, "Prevention")
      rule_set_type            = try(waf_configuration.value.rule_set_type, "OWASP")
      rule_set_version         = try(waf_configuration.value.rule_set_version, "3.2")
      file_upload_limit_mb     = try(waf_configuration.value.file_upload_limit_mb, 100)
      max_request_body_size_kb = try(waf_configuration.value.max_request_body_size_kb, 128)
      request_body_check       = try(waf_configuration.value.request_body_check, true)

      dynamic "disabled_rule_group" {
        for_each = try(waf_configuration.value.disabled_rule_groups, {})

        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = try(disabled_rule_group.value.rules, [])
        }
      }

      dynamic "exclusion" {
        for_each = try(waf_configuration.value.exclusion, {})

        content {
          match_variable          = exclusion.value.match_variable
          selector_match_operator = try(exclusion.value.selector_match_operator, null)
          selector                = try(exclusion.value.selector, null)
        }

      }
    }
  }

  dynamic "custom_error_configuration" {
    for_each = lookup(var.config, "custom_error_configuration", {})

    content {
      custom_error_page_url = custom_error_configuration.value.custom_error_page_url
      status_code           = custom_error_configuration.value.status_code
    }
  }

  dynamic "authentication_certificate" {
    for_each = lookup(var.config, "authentication_certificate", {})

    content {
      name = authentication_certificate.value.name
      data = authentication_certificate.value.data
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = lookup(var.config, "trusted_root_certificate", {})

    content {
      name                = trusted_root_certificate.value.name
      data                = try(trusted_root_certificate.value.data, null)
      key_vault_secret_id = try(trusted_root_certificate.value.key_vault_secret_id, null)
    }
  }

  dynamic "trusted_client_certificate" {
    for_each = lookup(var.config, "trusted_client_certificate", {})

    content {
      name = trusted_client_certificate.value.name
      data = trusted_client_certificate.value.data
    }
  }

  depends_on = [azurerm_role_assignment.kv_secret_user]

  lifecycle {
    create_before_destroy = true
  }
}

# user assigned identity
resource "azurerm_user_assigned_identity" "application_gateway_identity" {
  for_each = try(var.config.identity, null) != null ? { uai = var.config.identity } : {}

  name                = try(var.config.identity.name, "uai-${var.config.name}")
  resource_group_name = coalesce(try(var.config.identity.resource_group, null), try(var.config.resource_group, null), var.resource_group)
  location            = coalesce(try(var.config.identity.location, null), try(var.config.location, null), var.location)
}

# role assignment
resource "azurerm_role_assignment" "kv_secret_user" {
  for_each = try(var.config.identity, null) != null ? { uai = var.config.scope } : {}

  scope                = var.config.scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.application_gateway_identity["uai"].principal_id
}

# associate virtual machine interfaces
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "vm" {
  for_each = {
    for assoc in flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : [
          for pool_key, pool in lookup(listener, "backend_address_pools", {}) : [
            for vm_key, vm in lookup(pool, "network_interfaces", {}) : {
              key                   = "${app_key}-${listener_key}-${pool_key}-${vm_key}"
              pool_name             = try(pool.name, replace("bap-${app_key}-${listener_key}-${pool_key}", "_", "-"))
              network_interface_id  = vm.network_interface_id
              ip_configuration_name = vm.ip_configuration_name
            }
          ]
        ]
      ]
    ]) : assoc.key => assoc
  }

  network_interface_id  = each.value.network_interface_id
  ip_configuration_name = each.value.ip_configuration_name
  backend_address_pool_id = [
    for pool in azurerm_application_gateway.application_gateway.backend_address_pool : pool.id
    if pool.name == each.value.pool_name
  ][0]
}
