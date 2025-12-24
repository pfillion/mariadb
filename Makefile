SHELL = /bin/sh
.PHONY: help
.DEFAULT_GOAL := help

ifeq ($(MODE_LOCAL),true)
	GIT_CONFIG_GLOBAL := $(shell git config --global --add safe.directory /main/src > /dev/null)
endif

# Version
VERSION ?= 11.8.2-noble
VERSION_PARTS := $(subst ., ,$(VERSION))

MAJOR := $(word 1,$(VERSION_PARTS))
MINOR := $(word 2,$(VERSION_PARTS))
MICRO := $(word 3,$(VERSION_PARTS))

CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(MICRO)
CURRENT_VERSION_MINOR := $(MAJOR).$(MINOR)
CURRENT_VERSION_MAJOR := $(MAJOR)

DATE = $(shell date -u +"%Y-%m-%dT%H:%M:%S")
COMMIT := $(shell git rev-parse HEAD)
AUTHOR := $(firstword $(subst @, ,$(shell git show --format="%aE" $(COMMIT))))

# Bats parameters
TEST_FOLDER ?= $(shell pwd)/tests

# Docker parameters
NS ?= pfillion
IMAGE_NAME ?= mariadb
CONTAINER_NAME ?= mariadb
CONTAINER_INSTANCE ?= default

help: ## Show the Makefile help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bats-test: ## Test bash scripts
	bats --print-output-on-failure $(TEST_FOLDER)

docker-build: ## Build the image form Dockerfile
	chmod 755 -R ./rootfs/
	docker build \
		--build-arg DATE=$(DATE) \
		--build-arg CURRENT_VERSION_MICRO=$(CURRENT_VERSION_MICRO) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg AUTHOR=$(AUTHOR) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MINOR) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MAJOR) \
		-t $(NS)/$(IMAGE_NAME):latest \
		-f Dockerfile .

docker-push: ## Push the image to a registry
ifdef DOCKER_USERNAME
	@echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin
endif
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO)
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MINOR)
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MAJOR)
	docker push $(NS)/$(IMAGE_NAME):latest
    
docker-shell: docker-start ## Run shell command in the container
	docker exec -it $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/bash
	$(docker_stop)

docker-start: ## Run the container in background
	docker run -d --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) -e 'MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1' $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

docker-stop: ## Stop the container
	$(docker_stop)

docker-test: ## Run docker container tests
	container-structure-test test --image $(NS)/$(IMAGE_NAME):$(VERSION) --config $(TEST_FOLDER)/config.yaml

build: docker-build ## Build all

test: bats-test docker-test ## Run all tests

test-ci: ## Run CI pipeline locally
	woodpecker-cli exec --local --repo-trusted-volumes=true --env=MODE_LOCAL=true

release: build test docker-push ## Build and push the image to a registry

define docker_stop
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)
endef