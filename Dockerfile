ARG NEOFS_HUB_IMAGE=nspccdev/neofs
ARG NEOFS_HUB_TAG=latest
ARG NEOGO_HUB_IMAGE=nspccdev/neo-go
ARG NEOGO_HUB_TAG=latest
ARG NEOFS_REST_HUB_TAG=latest

FROM ${NEOGO_HUB_IMAGE}:${NEOGO_HUB_TAG} as neo-go
FROM ${NEOFS_HUB_IMAGE}-cli:${NEOFS_HUB_TAG} as neofs-cli
FROM ${NEOFS_HUB_IMAGE}-ir:${NEOFS_HUB_TAG} as neofs-ir
FROM ${NEOFS_HUB_IMAGE}-storage:${NEOFS_HUB_TAG} as neofs-storage
FROM ${NEOFS_HUB_IMAGE}-adm:${NEOFS_HUB_TAG} as neofs-adm
FROM ${NEOFS_HUB_IMAGE}-rest-gw:${NEOFS_REST_HUB_TAG} as neofs-rest-gw

# Executable image
FROM alpine AS neofs-aio
RUN apk add --no-cache \
  bash \
  ca-certificates \
  jq \
  expect \
  iputils \
  curl

WORKDIR /

COPY --from=neo-go /etc/ssl/certs /etc/ssl/certs
COPY --from=neo-go /usr/bin/neo-go /usr/bin/neo-go
COPY --from=neofs-cli /bin/neofs-cli /usr/bin/neofs-cli
COPY --from=neofs-ir /bin/neofs-ir /usr/bin/neofs-ir
COPY --from=neofs-storage /bin/neofs-node /usr/bin/neofs-node
COPY --from=neofs-adm /bin/neofs-adm /usr/bin/neofs-adm
COPY --from=neofs-rest-gw /bin/neofs-rest-gw /usr/bin/neofs-rest-gw

COPY ./sn/cli-cfg.yaml /config/cli-cfg-sn.yaml
COPY ./sn/wallet.json /config/wallet-sn.json
COPY ./sn/config.yaml /config/config-sn.yaml
COPY ./rest-gw/wallet.json /config/wallet-rest.json
COPY ./ir/cli-cfg.yaml /config/cli-cfg-ir.yaml
COPY ./ir/config.yaml /config/config-ir.yaml
COPY ./ir/node-wallet.json /config/node-wallet.json
COPY ./ir/node-config.yaml /config/node-config.yaml
COPY ./bin/ /config/bin

COPY ./rest-gw/rest.env /config/rest.env
RUN sed -ri 's,^([^=]+)=(.*)+$,\1=${\1-\2},' /config/rest.env

ENTRYPOINT ["/config/bin/init-aio.sh"]
