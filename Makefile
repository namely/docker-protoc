.PHONY: build
build:
	./build.sh

.PHONY: push
push: build
	./push.sh

.PHONY: export LATEST = true
push-latest:
	./push.sh

.PHONY: build-latest
build-latest:
	LATEST=true \
	./build.sh
