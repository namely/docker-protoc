.PHONY: build
build:
	bash ./build.sh

.PHONY: push
push: build
	bash ./push.sh

.PHONY: push-latest
push-latest:
	bash ./push.sh true

.PHONY: tag-latest
tag-latest:
	bash ./build.sh true
