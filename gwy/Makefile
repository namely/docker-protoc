
NAMESPACE=namely
NAME=gen-grpc-gateway
TAG=1.10
CONTAINER=$(NAMESPACE)/$(NAME):$(TAG)

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: test
test: build
	bash test.sh $(CONTAINER)

.PHONY: push
push: build test
	docker push $(CONTAINER)
