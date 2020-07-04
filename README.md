# Vault Enterprise Deployment and Configuration

Here we deploy vault enterprise on GCP using raft based on this guide:
https://learn.hashicorp.com/vault/operations/ops-deployment-guide-raft
and https://www.vaultproject.io/docs/configuration/storage/raft

Make sure you enable the enterprise license or else you get 30 minutes and then the node reseals and you have to restart the vault service.

The following guide is essential for setting up DR
https://learn.hashicorp.com/vault/operations/ops-disaster-recovery

The following guide is essential for setting up PR
https://learn.hashicorp.com/vault/operations/mount-filter

Here is the order to create the DR and PR replicas:
1. Create the Primary cluster's raft. Firewalls within a VPC still need to allow ports 22, 8200, 8201 ingress to all instances. I thought that a VPC allowed communication freely between any instances in the VPC but that is wrong, you have to explicitly specify that in the FW rules.
2. Enable DR replication on the Primary cluster as primary
3. Enable DR replication on the secondary clusters as secondary
4. Enable PR replication on the Primary cluster as primary
5. Enable PR replication on the secondary PR cluster
6. At this point the secondary PR cluster will lose its ability to auth to itself using its root token, you have two options as per https://learn.hashicorp.com/vault/operations/mount-filter#step-3-secondary-cluster-re-authentication. I opted for the second one.
  - Option 1: Use the auth methods configured on the primary cluster to log into the secondary
  - Option 2: Generate a new root token using the primary's unseal key
7. Enable DR replication on the PR secondary
8. Enable DR replication on the DR secondary for the PR secondary

