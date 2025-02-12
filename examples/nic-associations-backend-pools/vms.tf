locals {
  vms = {
    vm1 = {
      name         = "vm1"
      type         = "windows"
      size         = "Standard_D2ds_v5"
      timezone     = "W. Europe Standard Time"
      license_type = "Windows_Server"
      username     = "local-admin"
      password     = module.kv.secrets.vm1.value
      interfaces = {
        int1 = {
          subnet = module.network.subnets.shared.id
          dns_servers = [
            "10.18.20.10", "10.17.20.10",
            "10.21.20.4"
          ]
          ip_configurations = {
            conf1 = {
              primary            = true
              private_ip_address = "10.18.20.10"
            }
          }
        }
      }
      source_image_reference = {
        sku = "2019-Datacenter"
      }
    }
    vm2 = {
      name         = "vm2"
      type         = "windows"
      size         = "Standard_D4ds_v5"
      timezone     = "W. Europe Standard Time"
      license_type = "Windows_Server"
      username     = "local-admin"
      zone         = "1"
      password     = module.kv.secrets.vm2.value
      interfaces = {
        int1 = {
          subnet = module.network.subnets.shared.id
          dns_servers = [
            "10.18.20.15", "10.17.20.14"
          ]
          ip_configurations = {
            conf1 = {
              primary            = true
              private_ip_address = "10.18.20.15"
            }
          }
        }
      }
      source_image_reference = {
        sku = "2019-Datacenter"
      }
    }
  }
}
