terraform {
  required_providers {
    vault = "~> 2.11"
  }
}

provider "vault" {
  alias = "ns1"
  namespace = "ns1"
}

provider "vault" {
  alias = "ns2"
  namespace = "ns2"
}
