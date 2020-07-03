# Outputs file
output "vault_url" {
  value = "http://${google_compute_instance.vault-servers[var.instance_names.key].network_interface.0.access_config.0.nat_ip}:8200 to access ${each.key}"
}
