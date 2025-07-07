#!/bin/bash

# vault init
vault_init=$(kubectl -n vault exec -it vault-0 -- vault operator init -format=json)
export VAULT_TOKEN=$(echo "$vault_init" | jq -r '.root_token')
vault_pods_numbers=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o name | sed 's/.*-//g')


# generate vault deploument's creds
echo "$VAULT_TOKEN" > /tmp/vault_token

# generate unseal script
#echo "VAULT_ADDR=https://localhost:8200" > /tmp/vault_unseal.sh
#echo "VAULT_TOKEN=$VAULT_TOKEN" >> /tmp/vault_unseal.sh
#
#for pod_number in $vault_pods_numbers; do
#key=$(echo "$vault_init" | jq ".unseal_keys_b64[${pod_number}]")
#echo "vault operator unseal $key" >> /tmp/vault_unseal.sh
#done
#
#for pod_number in $vault_pods_numbers; do
#kubectl -n vault cp /tmp/vault_unseal.sh vault-${pod_number}:/vault/file/vault_unseal.sh
#done
#
## unseal first node
#kubectl -n vault exec -it vault-0 -- ash /vault/file/vault_unseal.sh
#sleep 10

for pod_number in $vault_pods_numbers; do
  if [ "$pod_number" != "0" ]
  then
    # join cluster
    kubectl -n vault exec -it vault-${pod_number} -- vault operator raft join -leader-ca-cert=@/vault/userconfig/vault-server-tls/vault.ca https://vault-0.vault-internal:8200 
    # unseal other node
    #kubectl -n vault exec -it vault-${pod_number} -- ash /vault/file/vault_unseal.sh
  fi
done