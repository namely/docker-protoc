
NAMESPACE=namely
NAME=protoc-all
TAG=latest
CONTAINER=$(NAMESPACE)/$(NAME):$(TAG)

.PHONY: build
build:
	docker build -t $(CONTAINER) ./all

.PHONY: test
test: build
	bash test.sh $(CONTAINER)

.PHONY: push
push: build test
	docker push $(CONTAINER)
