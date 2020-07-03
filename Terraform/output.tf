# Outputs file
output "vault_urls" {
  value = {
      for instance in google_compute_instance.vault-servers:
      instance.name => "http://${instance.network_interface.0.access_config.0.nat_ip}:8200"
      # "http://${google_compute_instance.vault-servers.network_interface.0.access_config.0.nat_ip}:8200 to access ${var.instance_names.key}"
  }
}
