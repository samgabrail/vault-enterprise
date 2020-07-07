variable "project" {
  description = "project to deploy kubernetes cluster into"
}

variable "location" {
  description = "location to deploy kubernetes cluster into"
  default     = "us-central1-a"
}

variable "instance_names" {
  type = map(string)
  default = {
  "vault-prim-uswest1-a": "us-west1-a",
  "vault-prim-uswest1-b": "us-west1-b",
  "vault-prim-uswest1-c": "us-west1-c", 
  "vault-dr-prim-uswest1-a": "us-west1-a",
  "vault-pr-useast1-b": "us-east1-b",
  "vault-dr-prim-useast1-c": "us-east1-c",
  "vault-dr-pr-useast1-d": "us-east1-d",
  "test-raft-snapshot": "us-east1-d"}
}

variable "machine_type" {
  description = "size of the compute resources"
  default     = "g1-small"
}

variable "dns_managed_zone" {
  default = "public-zone"
}

variable "dns_name" {
  default = "vault.hashidemos.tekanaid.com"
}