#!/usr/bin/env bash

# EpicChinGo binary path.
EPICCHAINGO="${EPICCHAINGO:-docker exec aio epicchain-go}"

# Wallet file to change config value
WALLET="${WALLET:-morph/node-wallet.json}"
CONFIG_IMG="${CONFIG:-/config/node-config.yaml}"

# Netmap contract address resolved by XNS
NETMAP_ADDR=$(./bin/resolve.sh netmap.epicchain) || die "Failed to resolve 'netmap.epicchain' domain name"

# e configuration record: key is a string and value is an int
KEY=${1}
VALUE="${2}"

[ -z "$KEY" ] && echo "Empty config key" && exit 1
[ -z "$VALUE" ] && echo "Empty config value" && exit 1

# Internal variables
ADDR=$(jq -r .accounts[2].address "${WALLET}")

# Change config value in side chain
echo "Changing ${KEY} configuration value to ${VALUE}"
${EPICCHAINGO} contract invokefunction \
	--wallet-config "${CONFIG_IMG}" \
  -a "${ADDR}" --force \
  -r http://localhost:30333 \
  "${NETMAP_ADDR}" \
  setConfig bytes:beefcafe \
  string:"${KEY}" \
  int:"${VALUE}" -- "${ADDR}" || exit 1

# Update epoch to apply new configuration value
./bin/tick.sh
