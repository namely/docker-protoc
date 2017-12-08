
NAMESPACE=namely
NAME_ALL=protoc-all
NAME_CLI=grpc_cli
TAG=latest
CONTAINER_ALL=$(NAMESPACE)/$(NAME_ALL):$(TAG)
CONTAINER_CLI=$(NAMESPACE)/$(NAME_CLI):$(TAG)

.PHONY: build
build:
	docker build -t $(CONTAINER_ALL) ./all
	docker build -t $(CONTAINER_CLI) -f all/Dockerfile.grpc_cli ./all

.PHONY: push
push:
	docker push $(CONTAINER)
	docker push $(CONTAINER_CLI)