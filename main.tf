resource "azurerm_application_gateway" "application_gateway" {
  name                              = var.config.name
  resource_group_name               = var.config.resource_group
  location                          = var.config.location
  firewall_policy_id                = try(var.config.firewall_policy_id, null)
  force_firewall_policy_association = try(var.config.force_firewall_policy_association, false)
  fips_enabled                      = try(var.config.fips_enabled, false)
  enable_http2                      = try(var.config.enable_http2, false)
  zones                             = try(var.config.zones, [])

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
      name                            = frontend_ip_configuration.value.name
      public_ip_address_id            = try(frontend_ip_configuration.value.public_ip_address_id, null)
      subnet_id                       = try(frontend_ip_configuration.value.subnet_id, null)
      private_ip_address              = try(frontend_ip_configuration.value.private_ip_address, null)
      private_ip_address_allocation   = try(frontend_ip_configuration.value.private_ip_address_allocation, "Dynamic")
      private_link_configuration_name = try(frontend_ip_configuration.value.private_link_configuration_name, null)
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
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : {
            key   = "${app_key}-${listener.name}-cert"
            value = listener.certificate
          } if lookup(listener, "certificate", null) != null
        ]
      ]) : item.key => item.value
    }
    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
      data                = try(ssl_certificate.value.data, null)
      password            = try(ssl_certificate.value.password, null)
    }
  }

  dynamic "http_listener" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : {
            key = "${app_key}-${listener.name}"
            value = merge(listener, {
              ssl_certificate_name = try(listener.certificate.name, null)
            })
          }
        ]
      ]) : item.key => item.value
    }
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      ssl_certificate_name           = try(http_listener.value.ssl_certificate_name, null)
      host_name                      = try(http_listener.value.host_name, null)
      require_sni                    = try(http_listener.value.require_sni, false)
    }
  }

  dynamic "backend_address_pool" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : [
            for pool_key, pool in listener.backend_pools : {
              key = "${app_key}-${listener.name}-${pool_key}"
              value = merge(pool, {
                name = "${listener.name}-${pool_key}"
              })
            }
          ]
        ]
      ]) : item.key => item.value
    }
    content {
      name         = backend_address_pool.value.name
      fqdns        = try(backend_address_pool.value.fqdns, [])
      ip_addresses = try(backend_address_pool.value.ip_addresses, [])
    }
  }

  dynamic "probe" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : [
            for pool_key, pool in listener.backend_pools : [
              for settings_key, settings in pool.http_settings : {
                key = "${app_key}-${listener.name}-${pool_key}-${settings_key}"
                value = merge(settings.probe, {
                  name = "${listener.name}-${pool_key}-${settings_key}"
                })
              } if lookup(settings, "probe", null) != null
            ]
          ]
        ]
      ]) : item.key => item.value
    }
    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = try(probe.value.host, null)
      interval                                  = try(probe.value.interval, 30)
      timeout                                   = try(probe.value.timeout, 30)
      unhealthy_threshold                       = try(probe.value.unhealthy_threshold, 3)
      pick_host_name_from_backend_http_settings = try(probe.value.pick_host_name_from_backend_http_settings, false)
      minimum_servers                           = try(probe.value.minimum_servers, null)
      match {
        body        = try(probe.value.match.body, null)
        status_code = try(probe.value.match.status_code, ["200-399"])
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : [
            for pool_key, pool in listener.backend_pools : [
              for settings_key, settings in pool.http_settings : {
                key = "${app_key}-${listener.name}-${pool_key}-${settings_key}"
                value = merge(settings, {
                  name       = "${listener.name}-${pool_key}-${settings_key}"
                  probe_name = "${listener.name}-${pool_key}-${settings_key}"
                })
              }
            ]
          ]
        ]
      ]) : item.key => item.value
    }
    content {
      name                                = backend_http_settings.value.name
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = try(backend_http_settings.value.cookie_based_affinity, "Disabled")
      request_timeout                     = try(backend_http_settings.value.request_timeout, 20)
      path                                = try(backend_http_settings.value.path, "/")
      probe_name                          = try(backend_http_settings.value.probe_name, null)
      host_name                           = try(backend_http_settings.value.host_name, null)
      pick_host_name_from_backend_address = try(backend_http_settings.value.pick_host_name_from_backend_address, false)
      affinity_cookie_name                = try(backend_http_settings.value.affinity_cookie_name, null)
      trusted_root_certificate_names      = try(backend_http_settings.value.trusted_root_certificate_names, [])
    }
  }

  dynamic "url_path_map" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : {
            key = "${app_key}-${listener.name}"
            value = merge(listener.routing.url_path_map, {
              name                               = "${listener.name}-pathmap"
              default_backend_address_pool_name  = "${listener.name}-${listener.routing.url_path_map.default_pool}"
              default_backend_http_settings_name = "${listener.name}-${listener.routing.url_path_map.default_pool}-${listener.routing.url_path_map.default_settings}"
              rewrite_rule_set_name              = lookup(listener, "rewrite_rules", null) != null ? "${listener.name}-rewrite" : null
            })
          } if lookup(listener.routing, "rule_type", "") == "PathBasedRouting" && lookup(listener.routing, "url_path_map", null) != null
        ]
      ]) : item.key => item.value
    }
    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_rewrite_rule_set_name       = try(url_path_map.value.rewrite_rule_set_name, null)
      default_redirect_configuration_name = try(url_path_map.value.default_redirect_configuration_name, null)

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.key
          paths                      = path_rule.value.paths
          backend_address_pool_name  = "${split("-pathmap", url_path_map.value.name)[0]}-${path_rule.value.pool}"
          backend_http_settings_name = "${split("-pathmap", url_path_map.value.name)[0]}-${path_rule.value.pool}-${path_rule.value.settings}"
          rewrite_rule_set_name      = url_path_map.value.rewrite_rule_set_name
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : {
            key = "${app_key}-${listener.name}"
            value = merge(listener.routing, {
              name                       = "${listener.name}-rule"
              http_listener_name         = listener.name
              url_path_map_name          = listener.routing.rule_type == "PathBasedRouting" ? "${listener.name}-pathmap" : null
              backend_address_pool_name  = listener.routing.rule_type == "Basic" ? "${listener.name}-${listener.routing.basic_config.pool}" : null
              backend_http_settings_name = listener.routing.rule_type == "Basic" ? "${listener.name}-${listener.routing.basic_config.pool}-${listener.routing.basic_config.settings}" : null
            })
          }
        ]
      ]) : item.key => item.value
    }
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = request_routing_rule.value.rule_type
      http_listener_name         = request_routing_rule.value.http_listener_name
      url_path_map_name          = try(request_routing_rule.value.url_path_map_name, null)
      backend_address_pool_name  = try(request_routing_rule.value.backend_address_pool_name, null)
      backend_http_settings_name = try(request_routing_rule.value.backend_http_settings_name, null)
      priority                   = request_routing_rule.value.priority
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = {
      for item in flatten([
        for app_key, app in var.config.applications : [
          for listener_key, listener in app.listeners : {
            key = "${app_key}-${listener.name}-rewrite"
            value = merge(listener.rewrite_rules, {
              name = "${listener.name}-rewrite"
              rules = {
                for rule_key, rule in listener.rewrite_rules.rules : rule_key => merge(rule, {
                  name = rule_key
                })
              }
            })
          } if lookup(listener, "rewrite_rules", null) != null
        ]
      ]) : item.key => item.value
    }
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rules
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = {
              for idx, condition in try(rewrite_rule.value.conditions, {}) :
              idx => condition
            }
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = try(condition.value.ignore_case, false)
              negate      = try(condition.value.negate, false)
            }
          }

          dynamic "request_header_configuration" {
            for_each = {
              for idx, config in try(rewrite_rule.value.request_header_configurations, {}) :
              idx => config
            }
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = {
              for idx, config in try(rewrite_rule.value.response_header_configurations, {}) :
              idx => config
            }
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }
        }
      }
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

resource "azurerm_user_assigned_identity" "application_gateway_identity" {
  name                = "uai-demo-dev"
  resource_group_name = var.resource_group
  location            = var.location
}

resource "azurerm_role_assignment" "kv_secret_user" {
  scope                = var.config.scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.application_gateway_identity.principal_id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "vm" {
  for_each = {
    for item in flatten([
      for app_key, app in var.config.applications : [
        for listener_key, listener in app.listeners : [
          for pool_key, pool in listener.backend_pools : [
            for vm_key, vm in try(pool.vm_associations, {}) : {
              key = "${app_key}-${listener.name}-${pool_key}-${vm_key}"
              value = {
                network_interface_id    = vm.network_interface_id
                ip_configuration_name   = vm.ip_configuration_name
                backend_address_pool_id = "${app_key}-${listener.name}-${pool_key}"
              }
            }
          ]
        ]
      ]
    ]) : item.key => item.value
  }

  network_interface_id    = each.value.network_interface_id
  ip_configuration_name   = each.value.ip_configuration_name
  backend_address_pool_id = [for pool in azurerm_application_gateway.application_gateway.backend_address_pool : pool.id if pool.name == each.value.backend_address_pool_id][0]
}
