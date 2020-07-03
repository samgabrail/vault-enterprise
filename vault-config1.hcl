storage "raft" {
  path          = "/Users/sam/Deployments/HashiCorp/vault_ent_raft/data1"
  redirect_addr = "http://127.0.0.1:8200"
  node_id = "raft_node_1"
}

cluster_addr = "http://127.0.0.1:8201"

ui = true
 
listener "tcp" {
 address     = "127.0.0.1:8200"
 tls_disable = 1
}
