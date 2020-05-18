.PHONY: build
build:
	bash ./build.sh

.PHONY: push
push: build
	bash ./push.sh

.PHONY: push-latest
push-latest:
	bash LATEST=true ./push.sh

.PHONY: build-latest
build-latest:
	bash LATEST=true ./build.sh
