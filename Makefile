SHELL = /bin/sh
.SUFFIXES:
.SUFFIXES: .c .o
.PHONY: help
.DEFAULT_GOAL := help

# Bats parameters
TEST_FOLDER ?= $(shell pwd)/tests

# Docker parameters
NS ?= pfillion
VERSION ?= latest
IMAGE_NAME ?= mariadb
CONTAINER_NAME ?= mariadb
CONTAINER_INSTANCE ?= default
VCS_REF=$(shell git rev-parse --short HEAD)
BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%S")

help: ## Show the Makefile help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bats-test: ## Test bash scripts
	bats $(TEST_FOLDER)

docker-build: ## Build the image form Dockerfile
	docker build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VERSION=$(VERSION) \
		-t $(NS)/$(IMAGE_NAME):$(VERSION) -f Dockerfile .

docker-rebuild: ## Rebuild the image form Dockerfile
	docker build  \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VERSION=$(VERSION) \
		--no-cache -t $(NS)/$(IMAGE_NAME):$(VERSION) -f Dockerfile .

docker-push: ## Push the image to a registry
	docker push $(NS)/$(IMAGE_NAME):$(VERSION)
    
docker-shell: ## Run shell command in the container
	docker run --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) -i -t $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION) /bin/sh

docker-run: ## Run the container
	docker run --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

docker-start: ## Run the container in background
	docker run -d --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

docker-stop: ## Stop the container
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

docker-rm: ## Remove the container
	docker rm $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

build: ## Build all
	make docker-build

rebuild: ## Build all
	make docker-rebuild

run: ## Run all
	make docker-run

test: ## Run all tests
	make bats-test

release: ## Build and push the image to a registry
	make build
	make test
	make docker-push