locals {
  redirect_configurations = {
    to_url = {
      name          = "redirect-${module.naming.application_gateway.name}-to-url"
      target_url    = "https://google.com"
      redirect_type = "Permanent"
      include_path  = true
      include_query = true
    }
    to_global = {
      name            = "redirect-${module.naming.application_gateway.name}-to-global"
      target_listener = "listener-${module.naming.application_gateway.name}-global"
      redirect_type   = "Permanent"
      include_path    = true
      include_query   = true
    }
  }
}
