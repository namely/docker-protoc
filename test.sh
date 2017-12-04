#!/bin/bash

LANGS=("go" "ruby" "csharp" "java" "python" "objc")

docker build -t namely/test-protoc-all ./all

# Generate proto files
for lang in ${LANGS[@]}; do
    echo "Testing language $lang"
    docker run --rm -v=`pwd`:/defs namely/test-protoc-all -f test/test.proto -l $lang -i test
    if [[ "$lang" == "go" ]]; then
      docker run --rm -v=`pwd`:/defs namely/test-protoc-all -d test -l $lang -o gen/dir/$lang --with-gateway
    fi

    if [[ ! -d gen/pb-$lang ]]; then
        echo "generated directory does not exist"
        exit 1
    fi
    if [[ ! -d gen/dir/$lang ]]; then
        echo "generated directory for all-file include method does not exist"
        exit 1
    fi
done
