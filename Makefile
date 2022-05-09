.PHONY: build
build:
	bash ./build.sh

.PHONY: test
test:
	bash ./all/test.sh

.PHONY: test-gwy
test-gwy:
	bash ./gwy/test.sh

# Not for manual invocation.
.PHONY: push
push: build
	bash ./push.sh

# Not for manual invocation; see .github/workflows/release.yml.
.PHONY: push-latest
push-latest:
	bash ./push.sh true

.PHONY: tag-latest
tag-latest:
	bash ./build.sh true
