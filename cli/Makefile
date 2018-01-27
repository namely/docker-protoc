
NAMESPACE=namely
NAME=grpc-cli
TAG=latest
CONTAINER=$(NAMESPACE)/$(NAME):$(TAG)

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: push
push: build
	docker push $(CONTAINER)
