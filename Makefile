.PHONY: build
build:
	bash ./build.sh

.PHONY: test
test:
	bash ./all/test.sh

.PHONY: push
push: build test
	docker push $(CONTAINER)

.PHONY: tag-latest
tag-latest:
	bash ./build.sh true
	
