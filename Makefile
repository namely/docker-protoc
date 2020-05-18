.PHONY: build
build:
	./build.sh

.PHONY: push
push: build
	./push.sh

.PHONY: build-latest
build-latest:
	LATEST=true \
	./build.sh

.PHONY: push-latest
push-latest: build-latest
	LATEST=true \
	./push.sh
