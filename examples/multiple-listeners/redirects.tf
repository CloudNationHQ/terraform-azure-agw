locals {
  redirect_configurations = {
    to_url = {
      target_url    = "https://google.com"
      redirect_type = "Permanent"
      include_path  = true
      include_query = true
    }
    to_global = {
      target_listener = "global"
      redirect_type   = "Permanent"
      include_path    = true
      include_query   = true
    }
  }
}
