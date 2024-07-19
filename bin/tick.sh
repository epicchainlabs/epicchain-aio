#!/usr/bin/env bash

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec aio neo-go}"

# Wallet file to change config value
WALLET="${WALLET:-./ir/node-wallet.json}"
CONFIG_IMG="${CONFIG:-/config/node-config.yaml}"

# Netmap contract address resolved by NNS
NETMAP_ADDR=$(./bin/resolve.sh netmap.neofs)

# Internal variables
ADDR=$(jq -r .accounts[2].address "${WALLET}")

# Fetch current epoch value
EPOCH=$(${NEOGO} contract testinvokefunction -r \
  http://localhost:30333 \
  "${NETMAP_ADDR}" \
  epoch | grep 'value' | awk -F'"' '{ print $4 }')

echo "Updating NeoFS epoch to $((EPOCH+1))"
${NEOGO} contract invokefunction \
  --wallet-config "${CONFIG_IMG}" \
  -a "${ADDR}" --force \
  -r http://localhost:30333 \
  "${NETMAP_ADDR}" \
  newEpoch int:$((EPOCH+1)) -- "${ADDR}":Global
