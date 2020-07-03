#!/bin/bash
apt update
apt install unzip -y
export VAULT_URL="https://releases.hashicorp.com/vault" \
         VAULT_VERSION="1.4.3+ent"
curl \
      --silent \
      --remote-name \
     "${VAULT_URL}/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"

curl \
      --silent \
      --remote-name \
      "${VAULT_URL}/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS"

curl \
      --silent \
      --remote-name \
      "${VAULT_URL}/${VAULT_VERSION}/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig"
unzip vault_${VAULT_VERSION}_linux_amd64.zip
chown root:root vault
mv vault /usr/local/bin/
vault -version
vault -autocomplete-install
complete -C /usr/local/bin/vault vault
setcap cap_ipc_lock=+ep /usr/local/bin/vault
useradd --system --home /etc/vault.d --shell /bin/false vault
mkdir --parents /etc/vault.d
touch /etc/vault.d/vault.hcl
chown --recursive vault:vault /etc/vault.d
chmod 640 /etc/vault.d/vault.hcl
mkdir /opt/raft
chown -R vault:vault /opt/raft
echo internal ip from within: ${internalip}
cat > /etc/vault.d/vault.hcl <<EOF
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable = 1
}
storage "raft" {
  path = "/opt/raft"
}
cluster_addr = "http://${internalip}:8201"
api_addr = "http://0.0.0.0:8200"
ui = true

EOF


cat > /etc/systemd/system/vault.service <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

EOF

systemctl enable vault
systemctl start vault

export VAULT_ADDR="http://127.0.0.1:8200"
vault status

echo "Script complete."