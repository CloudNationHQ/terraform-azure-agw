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
          dns_servers = [
            "10.18.20.10", "10.17.20.10",
            "10.21.20.4"
          ]
          ip_configurations = {
            conf1 = {
              subnet_id          = module.network.subnets.shared.id
              primary            = true
              private_ip_address = "10.18.20.10"
            }
          }
        }
      }
      source_image_reference = {
        offer     = "WindowsServer"
        publisher = "MicrosoftWindowsServer"
        sku       = "2022-Datacenter"
      }
    }
    vm2 = {
      name         = "vm2"
      type         = "windows"
      size         = "Standard_D2ds_v5"
      timezone     = "W. Europe Standard Time"
      license_type = "Windows_Server"
      username     = "local-admin"
      password     = module.kv.secrets.vm2.value
      interfaces = {
        int1 = {
          dns_servers = [
            "10.18.20.15", "10.17.20.14"
          ]
          ip_configurations = {
            conf1 = {
              subnet_id          = module.network.subnets.shared.id
              primary            = true
              private_ip_address = "10.18.20.15"
            }
          }
        }
      }
      source_image_reference = {
        offer     = "WindowsServer"
        publisher = "MicrosoftWindowsServer"
        sku       = "2022-Datacenter"
      }
    }
  }
}
