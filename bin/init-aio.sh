#!/bin/bash

## When we start AIO as a separate container or part of a docker-compose. In this case we move background tasks to foreground.
## Otherwise we may use AIO container like a base for own container, thus we need just run all AIO services, before our service.
IS_PURE_START="true"
## if "true" rest service will be started
IS_START_REST="true"

while getopts d:h:r: option; do
  case $option in
    d)
      IS_PURE_START="$OPTARG"
      ;;
    r)
      IS_START_REST="$OPTARG"
      ;;
  esac
done

export NEOGO=/usr/bin/neo-go
export WALLET=/config/node-wallet.json

/usr/bin/neofs-ir --config /config/config-ir.yaml &

while [[ -z "$(/usr/bin/neofs-cli control healthcheck --ir --endpoint localhost:16512 -c /config/cli-cfg-ir.yaml | grep 'Health status: READY')" ]];
do
  sleep 2;
done

CONSADDR=$(jq -r .accounts[2].address "${WALLET}")
SNADDR=$(jq -r  .accounts[0].address /config/wallet-sn.json)

${NEOGO} wallet nep17 transfer \
        --wallet-config /config/node-config.yaml \
        -r http://localhost:30333 \
        --from ${CONSADDR} --force \
        --to ${SNADDR} \
        --token GAS \
        --amount 100 \
	--await

set -m
/usr/bin/neofs-node --config /config/config-sn.yaml &

cd /config # tick.sh and config.sh require this working directory

while [[ -z "$(/usr/bin/neofs-cli control healthcheck --endpoint localhost:16513 -c /config/cli-cfg-sn.yaml | grep 'Network status: ONLINE')" ]];
do
  ./bin/tick.sh
  sleep 2
done

set -a

./bin/config.sh ContainerFee 0 && ./bin/config.sh ContainerAliasFee 0

if [ $IS_START_REST = "true" ]; then
    . /config/rest.env
    /usr/bin/neofs-rest-gw &

    while [[ "$(curl -s -o /dev/null -w %{http_code} $REST_GW_SERVER_ENDPOINTS_0_ADDRESS)" != "307" ]];
    do
      sleep 1;
    done
fi

echo "aio container started"

if [ $IS_PURE_START = "true" ]; then
    fg
fi
