resource "vault_namespace" "ns1" {
  path = "ns1"
}

resource "vault_namespace" "ns2" {
  path = "ns2"
}

resource "vault_namespace" "subns1" {
  provider = vault.ns1
  path = "subns1"
}

resource "vault_namespace" "subns2" {
  provider = vault.ns2
  path = "subns2"
}

resource "vault_auth_backend" "example" {
  provider = vault.ns1
  type = "userpass"
}

resource "vault_policy" "admin_policy" {
  provider = vault.ns1
  name   = "admins"
  policy = file("policies/admin_policy.hcl")
}

resource "vault_policy" "developer_policy" {
  provider = vault.ns2
  name   = "developers"
  policy = file("policies/developer_policy.hcl")
}

resource "vault_policy" "operations_policy" {
  name   = "operations"
  policy = file("policies/operation_policy.hcl")
}

resource "vault_mount" "admins" {
  provider = vault.ns1
  path        = "admins"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for admins."
}

resource "vault_mount" "developers" {
  provider = vault.ns2
  path        = "developers"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for Developers."
}

resource "vault_mount" "operations" {
  path        = "operations"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for Operations."
}

resource "vault_generic_secret" "admins_sample_data" {
  provider = vault.ns1
  path = "${vault_mount.admins.path}/test_account_admins"

  data_json = <<EOT
{
  "username": "foo-ns1-admins",
  "password": "bar-ns1-admins"
}
EOT
}

resource "vault_generic_secret" "developer_sample_data" {
  provider = vault.ns2
  path = "${vault_mount.developers.path}/test_account_developers"

  data_json = <<EOT
{
  "username": "foo",
  "password": "bar"
}
EOT
}



resource "vault_generic_secret" "developer_sample_data_ns2" {
  provider = vault.ns2
  path = "${vault_mount.developers.path}/test_account"

  data_json = <<EOT
{
  "username": "foo-ns2",
  "password": "bar-ns2"
}
EOT
}

// WebBlog Config

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

// resource "vault_kubernetes_auth_backend_config" "kubernetes_config" {
//   kubernetes_host    = "<K8s_host>"
//   kubernetes_ca_cert = "<K8s_cert>"
//   token_reviewer_jwt = "<jwt_token>"
// }

// You could use the above stanza to configure the K8s auth method by providing the proper values or do this manually inside the Vault container:
// vault write auth/kubernetes/config \
//    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
//    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
//    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

resource "vault_kubernetes_auth_backend_role" "webblog" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "webblog"
  bound_service_account_names      = ["webblog"]
  bound_service_account_namespaces = ["webblog"]
  token_ttl                        = 86400
  token_policies                   = ["webblog"]
}

resource "vault_policy" "webblog" {
  name   = "webblog"
  policy = file("policies/webblog_policy.hcl")
}

resource "vault_mount" "internal" {
  path        = "internal"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for WebBlog MongoDB."
}

resource "vault_generic_secret" "webblog" {
  path = "${vault_mount.internal.path}/webblog/mongodb"

  data_json = <<EOT
{
  "username": "${var.DB_USER}",
  "password": "${var.DB_PASSWORD}"
}
EOT
}

resource "vault_mount" "db" {
  path = "mongodb"
  type = "database"
  description = "Dynamic Secrets Engine for WebBlog MongoDB."
}

resource "vault_mount" "db_nomad" {
  path = "mongodb_nomad"
  type = "database"
  description = "Dynamic Secrets Engine for WebBlog MongoDB on Nomad."
}

// resource "vault_database_secret_backend_connection" "mongodb" {
//   backend       = vault_mount.db.path
//   name          = "mongodb"
//   allowed_roles = ["mongodb-role"]

//   mongodb {
//     connection_url = "mongodb://${var.DB_USER}:${var.DB_PASSWORD}@${var.DB_URL}/admin"
    
//   }
// }

// resource "vault_database_secret_backend_connection" "mongodb_nomad" {
//   backend       = vault_mount.db_nomad.path
//   name          = "mongodb_nomad"
//   allowed_roles = ["mongodb-nomad-role"]

//   mongodb {
//     connection_url = "mongodb://${var.DB_USER}:${var.DB_PASSWORD}@${var.DB_URL_NOMAD}/admin"
    
//   }
// }

// resource "vault_database_secret_backend_role" "mongodb-role" {
//   backend             = vault_mount.db.path
//   name                = "mongodb-role"
//   db_name             = vault_database_secret_backend_connection.mongodb.name
//   default_ttl         = "10"
//   max_ttl             = "86400"
//   creation_statements = ["{ \"db\": \"admin\", \"roles\": [{ \"role\": \"readWriteAnyDatabase\" }, {\"role\": \"read\", \"db\": \"foo\"}] }"]
// }

// resource "vault_database_secret_backend_role" "mongodb-nomad-role" {
//   backend             = vault_mount.db_nomad.path
//   name                = "mongodb-nomad-role"
//   db_name             = vault_database_secret_backend_connection.mongodb_nomad.name
//   default_ttl         = "10"
//   max_ttl             = "86400"
//   creation_statements = ["{ \"db\": \"admin\", \"roles\": [{ \"role\": \"readWriteAnyDatabase\" }, {\"role\": \"read\", \"db\": \"foo\"}] }"]
// }

resource "vault_mount" "transit" {
  path                      = "transit"
  type                      = "transit"
  description               = "To Encrypt the webblog"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "key" {
  backend = vault_mount.transit.path
  name    = "webblog-key"
  derived = "true"
  convergent_encryption = "true"
}

// ## PKI
// # https://learn.hashicorp.com/vault/secrets-management/sm-pki-engine
// # Create Root CA with TTL of 10 years
// vault secrets enable -path=pki pki
// vault secrets tune -max-lease-ttl=87600h pki
// vault write -field=certificate pki/root/generate/hashidemos common_name="hashidemos.tekanaid.com" \
//   ttl=876h > configs/pki/CA_cert.crt
// vault write pki/config/urls \
//   issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
//   crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"

// # Create Intermediate CA for one year TTL
// vault secrets enable -path=pki_int pki
// vault secrets tune -max-lease-ttl=43800h pki_int
// vault write -format=json pki_int/intermediate/generate/hashidemos \
//   common_name="hashidemos.tekanaid.com Intermediate Authority" \
//   | jq -r '.data.csr' > pki_intermediate.csr
// vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
//   format=pem_bundle ttl="8760h" \
//   | jq -r '.data.certificate' > intermediate.cert.pem
// vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

// # Create a Role
// vault write pki_int/roles/hashidemos \
//   allowed_domains="hashidemos.tekanaid.com" \
//   allow_subdomains=true \
//   max_ttl="730h"

// # Request Certificates
// vault write pki_int/issue/hashidemos common_name="webblog.hashidemos.tekanaid.com" ttl="24h"

// # Policies for vault agent
// # Permits token creation
// path "auth/token/create" {
//   capabilities = ["update"]
// }
// # Enable secrets engine
// path "sys/mounts/*" {
//   capabilities = ["create", "read", "update", "delete", "list"]
// }
// # List enabled secrets engine
// path "sys/mounts" {
//   capabilities = ["read", "list"]
// }
// # Work with pki secrets engine
// path "pki*" {
//   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
// }