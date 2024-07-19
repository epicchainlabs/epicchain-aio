#!/usr/bin/make -f

include .env
include help.mk

# Common variables
REPO=$(notdir $(shell pwd))
VERSION ?= "$(shell git describe --tags --match "v*" 2>/dev/null || git rev-parse --short HEAD | sed 's/^v//')"

# Variables for docker
NEOGO_HUB_IMAGE ?= "nspccdev/neo-go"
NEOFS_HUB_IMAGE ?= "nspccdev/neofs"
AIO_IMAGE ?= "$(NEOFS_HUB_IMAGE)-aio"

# Build aio Docker image
image-aio:
	@echo "⇒ Build aio docker image "
	@docker build \
		--rm \
		--build-arg NEOFS_HUB_IMAGE=$(NEOFS_HUB_IMAGE) \
        --build-arg NEOFS_HUB_TAG=$(AIO_VERSION) \
		--build-arg NEOGO_HUB_IMAGE=$(NEOGO_HUB_IMAGE) \
        --build-arg NEOGO_HUB_TAG=$(NEOGO_VERSION) \
        --build-arg NEOFS_REST_HUB_TAG=$(RESTGW_VERSION) \
		-f Dockerfile \
		-t $(AIO_IMAGE):$(AIO_VERSION) .

# Tick new epoch in side chain
tick.epoch:
	@./bin/tick.sh

# Show current version
version:
	@echo $(VERSION)
	@echo "neofs-node: $(AIO_VERSION)"
	@echo "neo-go: $(NEOGO_VERSION)"
	@echo "neofs-rest-gw: $(RESTGW_VERSION)"

