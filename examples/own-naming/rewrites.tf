locals {
  rewrite_rule_sets = {
    headers_blue = {
      name = "headers-${module.naming.application_gateway.name}-blue"
      rules = {
        add_custom_request_header = {
          rule_sequence = 100
          conditions    = {}
          request_header_configurations = {
            header1 = {
              header_name  = "X-Custom-Header"
              header_value = "CustomValue"
            }
          }
          response_header_configurations = {
            header1 = {
              header_name  = "X-Response-Custom"
              header_value = "ResponseValue"
            }
          }
        }
      }
    }
    headers_green = {
      name = "headers-${module.naming.application_gateway.name}-green"
      rules = {
        add_custom_request_header2 = {
          rule_sequence = 100
          conditions    = {}
          request_header_configurations = {
            header2 = {
              header_name  = "X-Custom-Header"
              header_value = "CustomValue"
            }
          }
          response_header_configurations = {
            header2 = {
              header_name  = "X-Response-Custom"
              header_value = "ResponseValue"
            }
          }
        }
      }
    }
  }
}
