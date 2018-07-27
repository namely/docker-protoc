
DOCKER_REPO ?=
NAMESPACE ?= namely
NAME ?= protoc-all
TAG ?= 1.13
CONTAINER = $(DOCKER_REPO)$(NAMESPACE)/$(NAME):$(TAG)

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: test
test: build
	bash test.sh $(CONTAINER)

.PHONY: push
push: build test
	docker push $(CONTAINER)
