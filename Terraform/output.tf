# Outputs file
output "vault_url" {
  for_each = var.instance_names
  value = "http://${google_compute_instance.vault-servers[each.key].network_interface.0.access_config.0.nat_ip}:8200 to access ${each.key}"
}
