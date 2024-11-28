resource "azurerm_application_gateway" "application_gateway" {
  name                              = var.config.name
  resource_group_name               = var.config.resource_group
  location                          = var.config.location
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

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.application_gateway_identity.id]
  }

  dynamic "gateway_ip_configuration" {
    for_each = var.config.gateway_ip_configurations
    content {
      name      = gateway_ip_configuration.value.name
      subnet_id = gateway_ip_configuration.value.subnet_id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.config.frontend_ip_configurations
    content {
      name                 = frontend_ip_configuration.value.name
      public_ip_address_id = frontend_ip_configuration.value.public_ip_address_id
    }
  }

  dynamic "frontend_port" {
    for_each = var.config.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "ssl_certificate" {
    for_each = distinct(flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : {
          name                = listener.certificate.name
          key_vault_secret_id = listener.certificate.key_vault_secret_id
        }
      ]
    ]))
    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
      data                = try(ssl_certificate.value.data, null)
      password            = try(ssl_certificate.value.password, null)
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = flatten([
      for app_key, app in var.config.applications :
      try([
        for rule_set_key, rule_set in app.rewrite_rule_sets : {
          name  = rule_set_key
          rules = rule_set.rules
        }
      ], [])
    ])

    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rules

        content {
          name          = rewrite_rule.key
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = rewrite_rule.value.conditions

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
          for pool_key, pool in try(listener.backend_pools, {}) : {
            name  = "${app_key}-${listener_key}-${pool_key}"
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
        for listener_key, listener in app.listeners : [
          for pool_key, pool in try(listener.backend_pools, {}) : [
            for setting_key, setting in pool.http_settings : {
              name                                = "${app_key}-${listener_key}-${pool_key}-${setting_key}"
              port                                = setting.port
              protocol                            = setting.protocol
              host_name                           = try(setting.host_name, null)
              cookie_based_affinity               = try(setting.cookie_based_affinity, "Disabled")
              request_timeout                     = try(setting.request_timeout, 30)
              probe_name                          = try(setting.probe != null, false) ? "${app_key}-${listener_key}-${pool_key}-${setting_key}" : null
              path                                = try(setting.path, "/")
              pick_host_name_from_backend_address = try(setting.pick_host_name_from_backend_address, false)
              affinity_cookie_name                = try(setting.affinity_cookie_name, null)
              trusted_root_certificate_names      = try(setting.trusted_root_certificate_names, [])
            }
          ]
        ]
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
    }
  }

  dynamic "probe" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : [
          for pool_key, pool in try(listener.backend_pools, {}) : [
            for setting_key, setting in pool.http_settings :
            # Only include settings with probes
            try(setting.probe != null, false) ? {
              name                                      = "${app_key}-${listener_key}-${pool_key}-${setting_key}"
              protocol                                  = setting.probe.protocol
              path                                      = setting.probe.path
              host                                      = setting.probe.host
              interval                                  = setting.probe.interval
              timeout                                   = setting.probe.timeout
              match_status_codes                        = setting.probe.match.status_code
              match_body                                = setting.probe.match.body
              port                                      = try(setting.probe.port, null)
              minimum_servers                           = try(setting.probe.minimum_servers, null)
              pick_host_name_from_backend_http_settings = try(setting.probe.pick_host_name_from_backend_http_settings, false)
              unhealthy_threshold                       = try(setting.probe.unhealthy_threshold, 3)
            } : null
          ]
        ]
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

      match {
        status_code = probe.value.match_status_codes
        body        = probe.value.match_body
      }
    }
  }

  dynamic "http_listener" {
    for_each = flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : {
          name                           = listener.name
          frontend_ip_configuration_name = listener.frontend_ip_configuration_name
          frontend_port_name             = listener.frontend_port_name
          protocol                       = listener.protocol
          host_name                      = listener.host_name
          require_sni                    = listener.require_sni
          ssl_certificate_name           = listener.certificate.name
          host_names                     = try(listener.host_names, [])
          ssl_profile_name               = try(listener.ssl_profile_name, null)
          firewall_policy_id             = try(listener.firewall_policy_id, null)
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
    }
  }

  # url path maps (only when path rules exist)
  dynamic "url_path_map" {
    for_each = merge(flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners :
        # only include if it's PathBasedRouting and has path rules
        try(listener.routing.rule_type, null) == "PathBasedRouting" ? {
          "${app_key}-${listener_key}" = {
            name                                = "${app_key}-${listener_key}-pathmap"
            default_backend_address_pool_name   = "${app_key}-${listener_key}-${listener.routing.url_path_map.default_pool}"
            default_backend_http_settings_name  = "${app_key}-${listener_key}-${listener.routing.url_path_map.default_pool}-${listener.routing.url_path_map.default_settings}"
            default_rewrite_rule_set_name       = try(listener.routing.url_path_map.default_rewrite_rule_set_name, null)
            default_redirect_configuration_name = try(listener.routing.url_path_map.default_redirect_configuration_name, null)
            path_rules                          = listener.routing.url_path_map.path_rules
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
          name                        = path_rule.key
          paths                       = path_rule.value.paths
          backend_address_pool_name   = "${split("-", url_path_map.value.name)[0]}-${split("-", url_path_map.value.name)[1]}-${path_rule.value.pool}"
          backend_http_settings_name  = "${split("-", url_path_map.value.name)[0]}-${split("-", url_path_map.value.name)[1]}-${path_rule.value.pool}-${path_rule.value.settings}"
          rewrite_rule_set_name       = try(path_rule.value.rewrite_rule_set_name, null)
          firewall_policy_id          = try(path_rule.value.firewall_policy_id, null)
          redirect_configuration_name = try(path_rule.value.redirect_configuration_name, null)
        }
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = {
      for redirect in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners :
          try(listener.routing.redirect_config, null) != null ? {
            key           = "${app_key}-${listener_key}"
            name          = "${app_key}-${listener_key}-redirect"
            redirect_type = listener.routing.redirect_config.redirect_type
            # handle either target_listener or target_url
            target_listener_name = try(
              listener.routing.redirect_config.target_listener != null ? (
                flatten([
                  for target_app_key, target_app in var.config.applications : [
                    for target_listener_key, target_listener in target_app.listeners :
                    target_listener.name if "${target_app_key}-${target_listener_key}" == "${app_key}-${listener.routing.redirect_config.target_listener}"
                  ]
                ])[0]
              ) : null,
              null
            )
            target_url           = try(listener.routing.redirect_config.target_url, null)
            include_path         = try(listener.routing.redirect_config.include_path, false)
            include_query_string = try(listener.routing.redirect_config.include_query, false)
          } : null
        ]
      ]) : redirect.key => redirect if redirect != null
    }
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
        for listener_key, listener in app.listeners : {
          name               = "${app_key}-${listener_key}"
          http_listener_name = listener.name
          rule_type          = listener.routing.rule_type
          priority           = listener.routing.priority

          backend_address_pool_name = (listener.routing.rule_type == "Basic" && try(listener.routing.backend_pool, null) != null) ? (
            "${app_key}-${listener_key}-${listener.routing.backend_pool}"
          ) : null

          backend_http_settings_name = (listener.routing.rule_type == "Basic" && try(listener.routing.backend_settings, null) != null) ? (
            "${app_key}-${listener_key}-${listener.routing.backend_pool}-${listener.routing.backend_settings}"
          ) : null

          url_path_map_name = listener.routing.rule_type == "PathBasedRouting" ? (
            "${app_key}-${listener_key}-pathmap"
          ) : null

          redirect_configuration_name = try(listener.routing.redirect_config, null) != null ? (
            "${app_key}-${listener_key}-redirect"
          ) : null

          rewrite_rule_set_name = try(listener.routing.rewrite_rule_set_name, null)
        }
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

  depends_on = [azurerm_role_assignment.kv_secret_user]

  lifecycle {
    create_before_destroy = true
  }
}

# user assigned identity
resource "azurerm_user_assigned_identity" "application_gateway_identity" {
  name                = "uai-demo-dev"
  resource_group_name = var.resource_group
  location            = var.location
}

# role assignment
resource "azurerm_role_assignment" "kv_secret_user" {
  scope                = var.config.scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.application_gateway_identity.principal_id
}

# associate virtual machine interfaces
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "vm" {
  for_each = {
    for assoc in flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : [
          for pool_key, pool in try(listener.backend_pools, {}) : [
            for vm_key, vm in try(pool.vm_associations, {}) : {
              key                   = "${app_key}-${listener_key}-${pool_key}-${vm_key}"
              pool_name             = "${app_key}-${listener_key}-${pool_key}"
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

# TODO: fix naming
# TODO: make identity, certificate blocks and user assigned identity and role assignment optional, because http settings can be used without them
# TODO: add type definitions
# TODO: add vault certificate authority issuer example
# TODO: backend settings should also be optional
