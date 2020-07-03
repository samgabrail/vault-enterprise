# Outputs file
output "vault_external_urls" {
  value = {
      for instance in google_compute_instance.vault-servers:
      instance.name => "http://${instance.network_interface.0.access_config.0.nat_ip}:8200"
  }
}


output "vault_internal_ips" {
  value = {
      for instance in google_compute_instance.vault-servers:
      instance.name => "${google_compute_instance.vault-servers[each.key].network_interface.0.network_ip}"
  }
}