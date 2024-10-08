#!/usr/bin/env bash

# EpicChainGo binary path.
NEOGO="${NEOGO:-docker exec aio neo-go}"
# XNS contract script hash
NNS_ADDR=$(curl -s --data '{ "id": 1, "jsonrpc": "2.0", "method": "getcontractstate", "params": [1] }' http://localhost:30333/ | jq -r '.result.hash')

${NEOGO} contract testinvokefunction \
  -r http://localhost:30333 \
  "${NNS_ADDR}" resolve string:"${1}" int:16 | jq -r '.stack[0].value | if type=="array" then .[0].value else . end' | base64 -d
