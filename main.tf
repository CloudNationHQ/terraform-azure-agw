data "azurerm_client_config" "current" {}

locals {
  resource_group_name = coalesce(
    lookup(
      var.config, "resource_group_name", null
    ), var.resource_group_name
  )

  location = coalesce(
    lookup(var.config, "location", null
    ), var.location
  )

  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name}"
  appgw_id  = "${local.parent_id}/providers/Microsoft.Network/applicationGateways/${var.config.name}"
  tags      = coalesce(var.config.tags, var.tags)

  gateway_ip_configurations = [
    for _, gateway_ip_configuration in var.config.gateway_ip_configurations : {
      name = gateway_ip_configuration.name
      properties = {
        subnet = {
          id = gateway_ip_configuration.subnet_id
        }
      }
    }
  ]

  private_link_configurations = [
    for private_link_configuration_key, private_link_configuration in var.config.private_link_configuration : {
      name = coalesce(private_link_configuration.name, private_link_configuration_key)
      properties = {
        ipConfigurations = [
          for ip_configuration_key, ip_configuration in private_link_configuration.ip_configurations : {
            name = coalesce(ip_configuration.name, ip_configuration_key)
            properties = {
              primary                   = ip_configuration.primary
              privateIPAddress          = ip_configuration.private_ip_address
              privateIPAllocationMethod = ip_configuration.private_ip_address_allocation
              subnet = {
                id = ip_configuration.subnet_id
              }
            }
          }
        ]
      }
    }
  ]

  private_link_configuration_ids = {
    for private_link_configuration in local.private_link_configurations :
    private_link_configuration.name => "${local.appgw_id}/privateLinkConfigurations/${private_link_configuration.name}"
  }

  frontend_ip_configurations = [
    for frontend_ip_configuration_key, frontend_ip_configuration in var.config.frontend_ip_configurations : {
      name = coalesce(frontend_ip_configuration.name, replace("fip-${frontend_ip_configuration_key}", "_", "-"))
      properties = {
        privateIPAddress          = frontend_ip_configuration.private_ip_address
        privateIPAllocationMethod = frontend_ip_configuration.private_ip_address_allocation
        privateLinkConfiguration = frontend_ip_configuration.private_link_configuration_name != null ? {
          id = local.private_link_configuration_ids[frontend_ip_configuration.private_link_configuration_name]
        } : null
        publicIPAddress = frontend_ip_configuration.public_ip_address_id != null ? {
          id = frontend_ip_configuration.public_ip_address_id
        } : null
        subnet = frontend_ip_configuration.subnet_id != null ? {
          id = frontend_ip_configuration.subnet_id
        } : null
      }
    }
  ]

  frontend_ports = [
    for frontend_port_key, frontend_port in var.config.frontend_ports : {
      name = coalesce(frontend_port.name, replace("fp-${frontend_port_key}", "_", "-"))
      properties = {
        port = frontend_port.port
      }
    }
  ]

  ssl_certificates = distinct(flatten([
    for app_key, app in var.config.applications : [
      for listener_key, listener in app.listeners :
      {
        name = listener.certificate.name
        properties = {
          keyVaultSecretId = listener.certificate.key_vault_secret_id
          data             = listener.certificate.data
          password         = listener.certificate.password
        }
    } if listener.certificate != null]
  ]))

  rewrite_rule_sets = [
    for rule_set_key, rule_set in var.config.rewrite_rule_sets : {
      name = coalesce(rule_set.name, replace("rwrs-${rule_set_key}", "_", "-"))
      properties = {
        rewriteRules = [
          for rewrite_rule_key, rewrite_rule in rule_set.rules : {
            name         = coalesce(rewrite_rule.name, replace("rwr-${rewrite_rule_key}", "_", "-"))
            ruleSequence = rewrite_rule.rule_sequence
            conditions = [
              for _, condition in rewrite_rule.conditions : {
                variable   = condition.variable
                pattern    = condition.pattern
                ignoreCase = condition.ignore_case
                negate     = condition.negate
              }
            ]
            actionSet = {
              requestHeaderConfigurations = [
                for _, request_header_configuration in rewrite_rule.request_header_configurations : {
                  headerName  = request_header_configuration.header_name
                  headerValue = request_header_configuration.header_value
                }
              ]
              responseHeaderConfigurations = [
                for _, response_header_configuration in rewrite_rule.response_header_configurations : {
                  headerName  = response_header_configuration.header_name
                  headerValue = response_header_configuration.header_value
                }
              ]
              urlConfiguration = rewrite_rule.url != null ? {
                modifiedPath        = rewrite_rule.url.path
                modifiedQueryString = rewrite_rule.url.query_string
                reroute             = rewrite_rule.url.reroute
              } : null
            }
          }
        ]
      }
    }
  ]

  backend_address_pools = flatten([
    for app_key, app in var.config.applications : [
      for pool_key, pool in app.backend_address_pools : {
        name = coalesce(pool.name, replace("bap-${app_key}-${pool_key}", "_", "-"))
        properties = {
          backendAddresses = concat(
            [for fqdn in pool.fqdns : { fqdn = fqdn }],
            [for ip_address in pool.ip_addresses : { ipAddress = ip_address }]
          )
        }
      }
    ]
  ])

  backend_address_pool_ids = {
    for pool in local.backend_address_pools :
    pool.name => "${local.appgw_id}/backendAddressPools/${pool.name}"
  }

  probes = flatten([
    for app_key, app in var.config.applications : [
      for setting_key, setting in app.backend_http_settings : {
        name = coalesce(setting.probe.name, replace("prb-${app_key}-${setting_key}", "_", "-"))
        properties = {
          protocol                            = coalesce(setting.probe.protocol, setting.protocol)
          path                                = setting.probe.path
          host                                = setting.probe.host
          interval                            = setting.probe.interval
          timeout                             = setting.probe.timeout
          port                                = setting.probe.port
          minServers                          = setting.probe.minimum_servers
          unhealthyThreshold                  = setting.probe.unhealthy_threshold
          pickHostNameFromBackendHttpSettings = setting.probe.pick_host_name_from_backend_http_settings
          match = try(setting.probe.match.status_code, null) != null ? {
            statusCodes = setting.probe.match.status_code
            body        = try(setting.probe.match.body, null)
          } : null
        }
      } if setting.probe != null
    ]
  ])

  probe_ids = {
    for probe in local.probes :
    probe.name => "${local.appgw_id}/probes/${probe.name}"
  }

  authentication_certificates = [
    for _, authentication_certificate in var.config.authentication_certificate : {
      name = authentication_certificate.name
      properties = {
        data = authentication_certificate.data
      }
    }
  ]

  authentication_certificate_ids = {
    for authentication_certificate in local.authentication_certificates :
    authentication_certificate.name => "${local.appgw_id}/authenticationCertificates/${authentication_certificate.name}"
  }

  trusted_root_certificates = [
    for _, trusted_root_certificate in var.config.trusted_root_certificate : {
      name = trusted_root_certificate.name
      properties = {
        data             = trusted_root_certificate.data
        keyVaultSecretId = trusted_root_certificate.key_vault_secret_id
      }
    }
  ]

  trusted_root_certificate_ids = {
    for trusted_root_certificate in local.trusted_root_certificates :
    trusted_root_certificate.name => "${local.appgw_id}/trustedRootCertificates/${trusted_root_certificate.name}"
  }

  trusted_client_certificates = [
    for _, trusted_client_certificate in var.config.trusted_client_certificate : {
      name = trusted_client_certificate.name
      properties = {
        data = trusted_client_certificate.data
      }
    }
  ]

  trusted_client_certificate_ids = {
    for trusted_client_certificate in local.trusted_client_certificates :
    trusted_client_certificate.name => "${local.appgw_id}/trustedClientCertificates/${trusted_client_certificate.name}"
  }

  backend_http_settings = flatten([
    for app_key, app in var.config.applications : [
      for setting_key, setting in app.backend_http_settings : {
        name = coalesce(setting.name, replace("bhs-${app_key}-${setting_key}", "_", "-"))
        properties = {
          port                           = setting.port
          protocol                       = setting.protocol
          hostName                       = setting.host_name
          cookieBasedAffinity            = setting.cookie_based_affinity
          requestTimeout                 = setting.request_timeout
          path                           = setting.path
          pickHostNameFromBackendAddress = setting.pick_host_name_from_backend_address
          affinityCookieName             = setting.affinity_cookie_name
          dedicatedBackendConnection     = setting.dedicated_backend_connection_enabled
          probe = setting.probe != null ? {
            id = local.probe_ids[coalesce(setting.probe.name, replace("prb-${app_key}-${setting_key}", "_", "-"))]
          } : null
          trustedRootCertificates = [
            for trusted_root_certificate_name in setting.trusted_root_certificate_names : {
              id = local.trusted_root_certificate_ids[trusted_root_certificate_name]
            }
          ]
          authenticationCertificates = [
            for _, authentication_certificate in setting.authentication_certificate : {
              id = local.authentication_certificate_ids[authentication_certificate.name]
            }
          ]
          connectionDraining = setting.connection_draining != null ? {
            enabled           = setting.connection_draining.enabled
            drainTimeoutInSec = setting.connection_draining.drain_timeout_sec
          } : null
        }
      }
    ]
  ])

  backend_http_setting_ids = {
    for setting in local.backend_http_settings :
    setting.name => "${local.appgw_id}/backendHttpSettingsCollection/${setting.name}"
  }

  ssl_certificate_ids = {
    for ssl_certificate in local.ssl_certificates :
    ssl_certificate.name => "${local.appgw_id}/sslCertificates/${ssl_certificate.name}"
  }

  rewrite_rule_set_ids = {
    for rewrite_rule_set in local.rewrite_rule_sets :
    rewrite_rule_set.name => "${local.appgw_id}/rewriteRuleSets/${rewrite_rule_set.name}"
  }

  frontend_ip_configuration_ids = {
    for frontend_ip_configuration in local.frontend_ip_configurations :
    frontend_ip_configuration.name => "${local.appgw_id}/frontendIPConfigurations/${frontend_ip_configuration.name}"
  }

  frontend_port_ids = {
    for frontend_port in local.frontend_ports :
    frontend_port.name => "${local.appgw_id}/frontendPorts/${frontend_port.name}"
  }

  ssl_profiles = [
    for _, ssl_profile in var.config.ssl_profile : {
      name = ssl_profile.name
      properties = {
        trustedClientCertificates = [
          for trusted_client_certificate_name in ssl_profile.trusted_client_certificate_names : {
            id = local.trusted_client_certificate_ids[trusted_client_certificate_name]
          }
        ]
        clientAuthConfiguration = {
          verifyClientCertIssuerDN = ssl_profile.verify_client_cert_issuer_dn
          verifyClientRevocation   = ssl_profile.verify_client_certificate_revocation
        }
        sslPolicy = ssl_profile.ssl_policy != null ? {
          policyType           = ssl_profile.ssl_policy.policy_type
          policyName           = ssl_profile.ssl_policy.policy_name
          cipherSuites         = ssl_profile.ssl_policy.policy_type == "Predefined" ? null : ssl_profile.ssl_policy.cipher_suites
          disabledSslProtocols = ssl_profile.ssl_policy.policy_type == "Predefined" ? null : ssl_profile.ssl_policy.disabled_protocols
          minProtocolVersion   = ssl_profile.ssl_policy.policy_type == "Predefined" ? null : ssl_profile.ssl_policy.min_protocol_version
        } : null
      }
    }
  ]

  ssl_profile_ids = {
    for ssl_profile in local.ssl_profiles :
    ssl_profile.name => "${local.appgw_id}/sslProfiles/${ssl_profile.name}"
  }

  http_listeners = flatten([
    for app_key, app in var.config.applications : [
      for listener_key, listener in app.listeners : {
        name = coalesce(listener.name, replace("lstn-${app_key}-${listener_key}", "_", "-"))
        properties = {
          frontendIPConfiguration = {
            id = local.frontend_ip_configuration_ids[contains(keys(var.config.frontend_ip_configurations), listener.frontend_ip_configuration_name) ? replace("fip-${listener.frontend_ip_configuration_name}", "_", "-") : listener.frontend_ip_configuration_name]
          }
          frontendPort = {
            id = local.frontend_port_ids[contains(keys(var.config.frontend_ports), listener.frontend_port_name) ? replace("fp-${listener.frontend_port_name}", "_", "-") : listener.frontend_port_name]
          }
          protocol                    = listener.protocol
          hostName                    = listener.host_name
          requireServerNameIndication = listener.require_sni
          sslCertificate = listener.certificate != null ? {
            id = local.ssl_certificate_ids[listener.certificate.name]
          } : null
          hostNames = listener.host_names
          sslProfile = listener.ssl_profile_name != null ? {
            id = local.ssl_profile_ids[listener.ssl_profile_name]
          } : null
          firewallPolicy = listener.firewall_policy_id != null ? {
            id = listener.firewall_policy_id
          } : null
          customErrorConfigurations = [
            for custom_error_configuration in listener.custom_error_configuration : {
              statusCode         = custom_error_configuration.status_code
              customErrorPageUrl = custom_error_configuration.custom_error_page_url
            }
          ]
        }
      }
    ]
  ])

  http_listener_ids = {
    for http_listener in local.http_listeners :
    http_listener.name => "${local.appgw_id}/httpListeners/${http_listener.name}"
  }

  redirect_configurations = flatten([
    for app_key, app in var.config.applications : [
      for redirect_key, redirect in var.config.redirect_configurations : {
        name = coalesce(redirect.name, replace("rdc-${redirect_key}", "_", "-"))
        properties = {
          redirectType = redirect.redirect_type
          targetListener = redirect.target_listener != null ? {
            id = local.http_listener_ids[contains(keys(app.listeners), redirect.target_listener) ? replace("lstn-${app_key}-${redirect.target_listener}", "_", "-") : redirect.target_listener]
          } : null
          targetUrl          = redirect.target_url
          includePath        = redirect.include_path
          includeQueryString = redirect.include_query_string
        }
      }
    ]
  ])

  redirect_configuration_ids = {
    for redirect_configuration in local.redirect_configurations :
    redirect_configuration.name => "${local.appgw_id}/redirectConfigurations/${redirect_configuration.name}"
  }

  url_path_maps = flatten([
    for app_key, app in var.config.applications : [
      for listener_key, listener in app.listeners :
      listener.routing_rule.rule_type == "PathBasedRouting" ? {
        name = coalesce(try(listener.routing_rule.url_path_map.name, null), replace("upm-${app_key}-${listener_key}", "_", "-"))
        properties = {
          defaultBackendAddressPool = listener.routing_rule.url_path_map.default_backend_address_pool_name != null ? {
            id = local.backend_address_pool_ids[contains(keys(app.backend_address_pools), listener.routing_rule.url_path_map.default_backend_address_pool_name) ? replace("bap-${app_key}-${listener.routing_rule.url_path_map.default_backend_address_pool_name}", "_", "-") : listener.routing_rule.url_path_map.default_backend_address_pool_name]
          } : null
          defaultBackendHttpSettings = listener.routing_rule.url_path_map.default_backend_http_settings_name != null ? {
            id = local.backend_http_setting_ids[contains(keys(app.backend_http_settings), listener.routing_rule.url_path_map.default_backend_http_settings_name) ? replace("bhs-${app_key}-${listener.routing_rule.url_path_map.default_backend_http_settings_name}", "_", "-") : listener.routing_rule.url_path_map.default_backend_http_settings_name]
          } : null
          defaultRewriteRuleSet = listener.routing_rule.url_path_map.default_rewrite_rule_set_name != null ? {
            id = local.rewrite_rule_set_ids[contains(keys(var.config.rewrite_rule_sets), listener.routing_rule.url_path_map.default_rewrite_rule_set_name) ? replace("rwrs-${listener.routing_rule.url_path_map.default_rewrite_rule_set_name}", "_", "-") : listener.routing_rule.url_path_map.default_rewrite_rule_set_name]
          } : null
          defaultRedirectConfiguration = listener.routing_rule.url_path_map.default_redirect_configuration_name != null ? {
            id = local.redirect_configuration_ids[contains(keys(var.config.redirect_configurations), listener.routing_rule.url_path_map.default_redirect_configuration_name) ? replace("rdc-${listener.routing_rule.url_path_map.default_redirect_configuration_name}", "_", "-") : listener.routing_rule.url_path_map.default_redirect_configuration_name]
          } : null
          pathRules = [
            for path_rule_key, path_rule in listener.routing_rule.url_path_map.path_rules : {
              name = coalesce(path_rule.name, path_rule_key)
              properties = {
                paths = path_rule.paths
                backendAddressPool = path_rule.backend_address_pool_name != null ? {
                  id = local.backend_address_pool_ids[contains(keys(app.backend_address_pools), path_rule.backend_address_pool_name) ? replace("bap-${app_key}-${path_rule.backend_address_pool_name}", "_", "-") : path_rule.backend_address_pool_name]
                } : null
                backendHttpSettings = path_rule.backend_http_settings_name != null ? {
                  id = local.backend_http_setting_ids[contains(keys(app.backend_http_settings), path_rule.backend_http_settings_name) ? replace("bhs-${app_key}-${path_rule.backend_http_settings_name}", "_", "-") : path_rule.backend_http_settings_name]
                } : null
                rewriteRuleSet = path_rule.rewrite_rule_set_name != null ? {
                  id = local.rewrite_rule_set_ids[contains(keys(var.config.rewrite_rule_sets), path_rule.rewrite_rule_set_name) ? replace("rwrs-${path_rule.rewrite_rule_set_name}", "_", "-") : path_rule.rewrite_rule_set_name]
                } : null
                redirectConfiguration = path_rule.redirect_configuration_name != null ? {
                  id = local.redirect_configuration_ids[contains(keys(var.config.redirect_configurations), path_rule.redirect_configuration_name) ? replace("rdc-${path_rule.redirect_configuration_name}", "_", "-") : path_rule.redirect_configuration_name]
                } : null
                firewallPolicy = path_rule.firewall_policy_id != null ? {
                  id = path_rule.firewall_policy_id
                } : null
              }
            }
          ]
        }
      } : null
    ]
  ])

  url_path_map_ids = {
    for url_path_map in local.url_path_maps :
    url_path_map.name => "${local.appgw_id}/urlPathMaps/${url_path_map.name}"
    if url_path_map != null
  }

  request_routing_rules = flatten([
    for app_key, app in var.config.applications : [
      for listener_key, listener in app.listeners : {
        name = coalesce(listener.routing_rule.name, replace("rrr-${app_key}-${listener_key}", "_", "-"))
        properties = {
          ruleType = listener.routing_rule.rule_type
          priority = listener.routing_rule.priority
          httpListener = {
            id = local.http_listener_ids[coalesce(listener.name, replace("lstn-${app_key}-${listener_key}", "_", "-"))]
          }
          backendAddressPool = (listener.routing_rule.rule_type == "Basic" && listener.routing_rule.backend_address_pool_name != null) ? {
            id = local.backend_address_pool_ids[contains(keys(app.backend_address_pools), listener.routing_rule.backend_address_pool_name) ? replace("bap-${app_key}-${listener.routing_rule.backend_address_pool_name}", "_", "-") : listener.routing_rule.backend_address_pool_name]
          } : null
          backendHttpSettings = (listener.routing_rule.rule_type == "Basic" && listener.routing_rule.backend_http_settings_name != null) ? {
            id = local.backend_http_setting_ids[contains(keys(app.backend_http_settings), listener.routing_rule.backend_http_settings_name) ? replace("bhs-${app_key}-${listener.routing_rule.backend_http_settings_name}", "_", "-") : listener.routing_rule.backend_http_settings_name]
          } : null
          urlPathMap = listener.routing_rule.rule_type == "PathBasedRouting" ? {
            id = local.url_path_map_ids[coalesce(try(listener.routing_rule.url_path_map.name, null), replace("upm-${app_key}-${listener_key}", "_", "-"))]
          } : null
          redirectConfiguration = (listener.routing_rule.rule_type == "Basic" && listener.routing_rule.redirect_configuration_name != null) ? {
            id = local.redirect_configuration_ids[contains(keys(var.config.redirect_configurations), listener.routing_rule.redirect_configuration_name) ? replace("rdc-${listener.routing_rule.redirect_configuration_name}", "_", "-") : listener.routing_rule.redirect_configuration_name]
          } : null
          rewriteRuleSet = listener.routing_rule.rewrite_rule_set_name != null ? {
            id = local.rewrite_rule_set_ids[contains(keys(var.config.rewrite_rule_sets), listener.routing_rule.rewrite_rule_set_name) ? replace("rwrs-${listener.routing_rule.rewrite_rule_set_name}", "_", "-") : listener.routing_rule.rewrite_rule_set_name]
          } : null
        }
      }
    ]
  ])

  resource_body = {
    zones = var.config.zones

    properties = {
      sku = {
        name     = var.config.sku.name
        tier     = var.config.sku.tier
        capacity = var.config.sku.capacity
      }
      firewallPolicy = var.config.firewall_policy_id != null ? {
        id = var.config.firewall_policy_id
      } : null
      forceFirewallPolicyAssociation = var.config.force_firewall_policy_association
      enableFips                     = var.config.fips_enabled
      enableHttp2                    = var.config.enable_http2
      globalConfiguration = var.config.global != null ? {
        enableRequestBuffering  = var.config.global.request_buffering_enabled
        enableResponseBuffering = var.config.global.response_buffering_enabled
      } : null
      gatewayIPConfigurations       = local.gateway_ip_configurations
      privateLinkConfigurations     = local.private_link_configurations
      frontendIPConfigurations      = local.frontend_ip_configurations
      frontendPorts                 = local.frontend_ports
      sslCertificates               = local.ssl_certificates
      rewriteRuleSets               = local.rewrite_rule_sets
      backendAddressPools           = local.backend_address_pools
      backendHttpSettingsCollection = local.backend_http_settings
      probes                        = local.probes
      httpListeners                 = local.http_listeners
      urlPathMaps                   = [for url_path_map in local.url_path_maps : url_path_map if url_path_map != null]
      redirectConfigurations        = local.redirect_configurations
      requestRoutingRules           = local.request_routing_rules
      autoscaleConfiguration = var.config.autoscale_configuration != null ? {
        minCapacity = var.config.autoscale_configuration.min_capacity
        maxCapacity = var.config.autoscale_configuration.max_capacity
      } : null
      sslPolicy = var.config.ssl_policy != null ? {
        policyType           = var.config.ssl_policy.policy_type
        policyName           = var.config.ssl_policy.policy_name
        cipherSuites         = var.config.ssl_policy.policy_type == "Predefined" ? null : var.config.ssl_policy.cipher_suites
        disabledSslProtocols = var.config.ssl_policy.policy_type == "Predefined" ? null : var.config.ssl_policy.disabled_protocols
        minProtocolVersion   = var.config.ssl_policy.policy_type == "Predefined" ? null : var.config.ssl_policy.min_protocol_version
      } : null
      sslProfiles = local.ssl_profiles
      webApplicationFirewallConfiguration = var.config.waf_configuration != null ? {
        enabled                = var.config.waf_configuration.enabled
        firewallMode           = var.config.waf_configuration.firewall_mode
        ruleSetType            = var.config.waf_configuration.rule_set_type
        ruleSetVersion         = var.config.waf_configuration.rule_set_version
        fileUploadLimitInMb    = var.config.waf_configuration.file_upload_limit_mb
        maxRequestBodySizeInKb = var.config.waf_configuration.max_request_body_size_kb
        requestBodyCheck       = var.config.waf_configuration.request_body_check
        disabledRuleGroups = [
          for _, disabled_rule_group in var.config.waf_configuration.disabled_rule_groups : {
            ruleGroupName = disabled_rule_group.rule_group_name
            rules         = disabled_rule_group.rules
          }
        ]
        exclusions = [
          for _, exclusion in var.config.waf_configuration.exclusion : {
            matchVariable         = exclusion.match_variable
            selectorMatchOperator = exclusion.selector_match_operator
            selector              = exclusion.selector
          }
        ]
      } : null
      customErrorConfigurations = [
        for _, custom_error_configuration in var.config.custom_error_configuration : {
          customErrorPageUrl = custom_error_configuration.custom_error_page_url
          statusCode         = custom_error_configuration.status_code
        }
      ]
      authenticationCertificates = local.authentication_certificates
      trustedRootCertificates    = local.trusted_root_certificates
      trustedClientCertificates  = local.trusted_client_certificates
    }
  }
}

resource "azapi_resource" "this" {
  location  = local.location
  name      = var.config.name
  parent_id = local.parent_id
  type      = "Microsoft.Network/applicationGateways@2025-03-01"
  body      = local.resource_body
  tags      = local.tags

  ignore_null_property = true
  list_unique_id_property = {
    "properties.frontendIPConfigurations"                        = "name"
    "properties.backendAddressPools"                             = "name"
    "properties.backendHttpSettingsCollection"                   = "name"
    "properties.frontendPorts"                                   = "name"
    "properties.backendAddressPools.properties.backendAddresses" = "ipAddress"
    "properties.httpListeners"                                   = "name"
    "properties.requestRoutingRules"                             = "name"
    "properties.probes"                                          = "name"
    "properties.redirectConfigurations"                          = "name"
    "properties.rewriteRuleSets"                                 = "name"
    "properties.sslCertificates"                                 = "name"
    "properties.urlPathMaps"                                     = "name"
  }
  response_export_values    = []
  schema_validation_enabled = true

  dynamic "identity" {
    for_each = var.config.identity != null ? { default = var.config.identity } : {}
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  depends_on = [azurerm_role_assignment.this]

  lifecycle {
    create_before_destroy = true
  }
}

moved {
  from = azurerm_application_gateway.this
  to   = azapi_resource.this
}

resource "azurerm_role_assignment" "this" {
  for_each = var.config.role_assignment != null ? { kv = var.config.role_assignment } : {}

  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_name                   = "Key Vault Secrets User"
  role_definition_id                     = each.value.role_definition_id
  principal_id                           = each.value.principal_id
  principal_type                         = each.value.principal_type
  description                            = "Role Based Access Control for Application Gateway to access Key Vault Secrets"
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
  for_each = {
    for assoc in flatten([
      for app_key, app in var.config.applications : [
        for pool_key, pool in app.backend_address_pools : [
          for vm_key, vm in pool.network_interfaces : {
            key                   = "${pool_key}-${vm_key}"
            pool_name             = coalesce(pool.name, replace("bap-${app_key}-${pool_key}", "_", "-"))
            network_interface_id  = vm.network_interface_id
            ip_configuration_name = vm.ip_configuration_name
          }
        ]
      ]
    ]) : assoc.key => assoc
  }

  network_interface_id    = each.value.network_interface_id
  ip_configuration_name   = each.value.ip_configuration_name
  backend_address_pool_id = local.backend_address_pool_ids[each.value.pool_name]

  depends_on = [azapi_resource.this]
}
