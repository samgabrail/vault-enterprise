# Vault Enterprise Deployment and Configuration

Here we deploy vault enterprise on GCP using raft based on this guide:
https://learn.hashicorp.com/vault/operations/ops-deployment-guide-raft
and https://www.vaultproject.io/docs/configuration/storage/raft

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

## Important Notes:
- Make sure you enable the enterprise license or else you get 30 minutes and then the node reseals and you have to restart the vault service.
- When log into a Raft follower node, there is only one root token and unseal keys for the whole raft cluster
- You can run the `vault operator raft list-peers` command on any of the Raft members.
- For Raft, with 3 members in a cluster, when the leader fails, you get one of the two remaining becomes a leader. If the next leader or even if the follower fails, you're out of luck. The last node is stuck in standby mode and can't serve you. When you bring back that last leader and unseal it. It becomes a follower and the other node becomes the active leader. During all of this the PR node works completely fine. So basically you can sustain only one failure in a 3 node raft cluster.
- When all members of Raft on the Primary cluster are down the PR Secondary doesn't become Primary it remains Secondary serving traffic. However, if you try to create a new KV secret it fails with the following Error: `1 error occurred: * rpc error: code = Unavailable desc = all SubConns are in TransientFailure, latest connection error: connection error: desc = "transport: Error while dialing remote error: tls: internal error`. However, when the Primary cluster is back up, you can write on the PR secondary no problem and that gets replicated to the Primary.
- When killing the PR secondary and promoting its DR (vault-dr-pr-useast1-d), you need to generate an operation token, you do that by supplying the unseal master key of the primary Raft cluster! Then you need to run a command similar to the below but not on the DR node, it has to go on the primary Raft cluster where you used the unseal master key: `vault operator generate-root -otp="IMuVne4QilgpFdm2J9DXx8aiBu" -decode="OmMAJlwdfmEMIl4ePgwYehxqNCoQdwBaL0c"` Then the DR will come up unsealed and you need to supply the root token of the PR secondary to log in. Now this promoted cluster is not connected to the Primary Raft cluster. Any changes on the Primary Raft Cluster don't get reflected here. You also can't write secrets to this DR cluster. Under the UI Status dropdown, you see that this node became DR Primary and that the vault-pr-useast1-b which is the Secondary PR is still shown as the secondary PR and that's why no replication happens between the regions.
- When you restore the PR secondary, you need to supply the unseal key of the Primary Raft cluster
- To restore things to normal that DR (vault-dr-pr-useast1-d) needs to have both PR and DR replication disabled. Then on the PR primary you need to revoke its DR secondary and rejoin the DR to return the initial state. All data on the DR will be wiped at this point. These are the two options available according to https://learn.hashicorp.com/vault/operations/ops-disaster-recovery#workflow:
Option 1 - Demote DR Primary to Secondary
Option 2 - Disable the original DR Primary
- You can also use a batch token starting with Vault 1.4 as per https://learn.hashicorp.com/vault/operations/ops-disaster-recovery#dr-operation-token-strategy
