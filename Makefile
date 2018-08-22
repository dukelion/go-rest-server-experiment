PHONY: clean test lint fmt docker docker_cleanbuild docker_cleanimages all
.DEFAULT_GOAL := all

SHELL := /bin/sh
# Go parameters
GOCMD=$(shell which go)
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOFMT=$(GOCMD) fmt
GOBIN=$(GOPATH)/bin
PROJECT_PATH=$(realpath $(shell dirname $(lastword $(MAKEFILE_LIST))))
GOPATH ?= "/src"

GOLANGCI_LINT_VERSION=1.9.3
GOLANGCI_LINT_ARCHIVE=golangci-lint-$(GOLANGCI_LINT_VERSION)-linux-amd64.tar.gz

TARGET=unity-test

all: fmt lint deps build test

clean:
	rm -f $(TARGET)

test:
	$(GOTEST) -v ./...

fmt:
	$(GOFMT)  ./...

deps: $(GOBIN)/dep 
	$(shell $(GOBIN)/dep ensure)
	@echo "Using gopath: $(GOPATH)"

build: deps
	@echo "Buildin $(TARGET)"
	$(shell CGO_ENABLED=0 $(GOBUILD) -o $(TARGET) -v main.go)


docker:
	docker build -t unity-test $(PROJECT_PATH)

docker_cleanbuild:
	docker build -t --no-cache unity-test $(PROJECT_PATH)

docker_cleanimages:
	$(shell docker rmi $$(docker images -q --filter "dangling=true"))

docker_run:
	if [ -n "$(shell docker ps -aq --filter name=unity-test)" ]; then \
		docker stop unity-test; \
		docker rm unity-test; \
	fi
	IRON_TOKEN=$(shell jq -r .token ~/iron.json)
	IRON_PROJECT_ID=$(shell jq -r .project_id ~/iron.json) 
	docker run -d -e IRON_TOKEN=$(IRON_TOKEN) -e IRON_PROJECT_ID=$(IRON_PROJECT_ID) --name unity-test -p 8080:8080 unity-test
	

$(GOBIN)/dep:
	$(GOGET) -u github.com/golang/dep/cmd/dep

$(GOBIN)/golangci-lint/golangci-lint:
	curl -OL https://github.com/golangci/golangci-lint/releases/download/v$(GOLANGCI_LINT_VERSION)/$(GOLANGCI_LINT_ARCHIVE)
	mkdir -p $(GOBIN)/golangci-lint/
	tar -xf $(GOLANGCI_LINT_ARCHIVE) --strip-components=1 -C $(GOBIN)/golangci-lint/
	rm -f $(GOLANGCI_LINT_ARCHIVE)


lint: $(GOBIN)/golangci-lint/golangci-lint
	find . -path ./vendor -prune -o -name \*.go | $(GOBIN)/golangci-lint/golangci-lint run
	yamllint k8s/

