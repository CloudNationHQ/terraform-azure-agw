module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "network" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 8.0"

  naming = local.naming

  vnet = {
    name           = module.naming.virtual_network.name
    address_space  = ["10.18.0.0/16"]
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

    subnets = {
      gw = {
        address_prefixes = ["10.18.1.0/24"]
        network_security_group = {
          rules = local.rules
        }
      }
      shared = {
        address_prefixes = ["10.18.20.0/26"]
        network_security_group = {
          name  = "nsg-shared-westeurope-001"
          rules = {}
        }
      }
    }
  }
}

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 3.0"
  naming  = local.naming

  vault = {
    name           = module.naming.key_vault.name_unique
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    certs          = local.certs

    secrets = {
      random_string = {
        vm1 = {
          name        = "vm1"
          length      = 24
          min_lower   = 4
          min_numeric = 4
          min_special = 4
          min_upper   = 4
        }
        vm2 = {
          name        = "vm2"
          length      = 24
          min_lower   = 4
          min_numeric = 4
          min_special = 4
          min_upper   = 4
        }
      }
    }
  }
}

module "public_ip" {
  source  = "cloudnationhq/pip/azure"
  version = "~> 2.0"

  configs = {
    fe = {
      name           = module.naming.public_ip.name
      location       = module.rg.groups.demo.location
      resource_group = module.rg.groups.demo.name

      zones = ["1", "2", "3"]
    }
  }
}

module "vms" {
  source  = "cloudnationhq/vm/azure"
  version = "~> 5.0"

  naming = local.naming

  keyvault       = module.kv.vault.id
  location       = module.rg.groups.demo.location
  resource_group = module.rg.groups.demo.name
  depends_on     = [module.kv]

  for_each = local.vms

  instance = each.value
}

module "application_gateway" {
  source  = "cloudnationhq/agw/azure"
  version = "~> 1.0"

  resource_group = module.rg.groups.demo.name
  location       = module.rg.groups.demo.location

  config = {
    scope          = module.kv.vault.id
    name           = module.naming.application_gateway.name
    resource_group = module.rg.groups.demo.name
    location       = module.rg.groups.demo.location

    sku = {
      name     = "Standard_v2"
      tier     = "Standard_v2"
      capacity = 2
    }

    identity = {
      type = "UserAssigned"
    }

    gateway_ip_configurations = {
      main = {
        name      = "gateway-ip-configuration"
        subnet_id = module.network.subnets.gw.id
      }
    }

    frontend_ip_configurations = {
      public = {
        name                 = "feip-prod-westus-001"
        public_ip_address_id = module.public_ip.configs.fe.id
      }
    }

    frontend_ports = {
      https = {
        name = "fep-prod-westus-001"
        port = 443
      }
    }

    applications = {
      mobile = local.mobile
    }
  }
}
