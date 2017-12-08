
NAMESPACE=namely
NAME=protoc-all
TAG=latest
CONTAINER=$(NAMESPACE)/$(NAME):$(TAG)

.PHONY: build
build:
	docker build -t $(CONTAINER) ./all

.PHONY: push
push:
	docker push $(CONTAINER)