#!/bin/bash

LANGS=("go" "ruby" "csharp" "java" "python" "objc")

docker build -t namely/test-protoc-all ./all

# Generate proto files
for lang in ${LANGS[@]}; do
    echo "Testing language $lang"
    docker run --rm -v=`pwd`:/defs namely/test-protoc-all -f test.proto -l $lang
    if [[ ! -d gen/pb-$lang ]]; then
        echo "generated directory does not exist"
        exit 1
    fi
done

