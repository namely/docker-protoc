.PHONY: build
build:
	bash ./hooks/build

.PHONY: push
push: build
	bash ./hooks/push

.PHONY: push-latest
push-latest:
	bash ./hooks/push true

.PHONY: tag-latest
tag-latest:
	bash ./hooks/build true
