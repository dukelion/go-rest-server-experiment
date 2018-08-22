PHONY: clean test lint fmt docker docker_cleanbuild docker_cleanimages all k8s_service
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
export GCLOUD_PROJECT=$(shell gcloud config get-value project -q)
GCLOUD_IMAGE=gcr.io/$(GCLOUD_PROJECT)/unity-test:latest

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

docker_gcloud_push: docker
	docker tag unity-test $(GCLOUD_IMAGE)
	gcloud docker --verbosity=error -- push $(GCLOUD_IMAGE)

k8s_secrets:
	k8s/create_secrets.sh

k8s_remove_secrets:
	kubectl delete secrets ironmq-creds

k8s_pod:
	k8s/create_pod.sh 
	sleep 5

k8s_remove_pod:
	kubectl delete deploy unity-test 

k8s_service:
	k8s/wait_deploy.sh unity-test 30 && kubectl expose deployment/unity-test --type=LoadBalancer --name=unity-test-svc

k8s_remove_service:
	kubectl delete svc unity-test-svc

k8s_ingress:
	k8s/create_ingress_google.sh

k8s_remove_ingress:
	kubectl delete ing test-ingress

deploy_gke: k8s_secrets k8s_pod k8s_service k8s_ingress
	k8s/k8s_test.sh

remove_gke: k8s_remove_ingress k8s_remove_service k8s_remove_pod k8s_remove_secrets


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

