#!/bin/bash

LANGS=("go" "ruby" "csharp" "java" "python" "objc")

# Checks that directories were appropriately created, and deletes the generated directory.
testGeneration() {
  lang=$1
  extra_arg=$2
  echo "Testing language $lang $extra_arg"

  # Test calling a file directly.
  docker run --rm -v=`pwd`:/defs namely/test-protoc-all -f test/test.proto -l $lang -i test $extra_arg
  if [[ ! -d "gen/pb-$lang" ]]; then
      echo "generated directory does not exist"
      exit 1
  fi
  rm -rf gen/

  # Test scanning a dir.
  docker run --rm -v=`pwd`:/defs namely/test-protoc-all -d test -l $lang -o gen/dir/$lang $extra_arg
  if [[ ! -d gen/dir/$lang ]]; then
    echo "generated directory for all-file include method does not exist"
    exit 1
  fi
  rm -rf gen/

  echo "Passed!"
}

docker build -t namely/test-protoc-all ./all

# Test grpc-gateway generation.
testGeneration go --with-gateway

# Generate proto files
for lang in ${LANGS[@]}; do
    testGeneration "$lang"
done

# Test grpc-gateway Docker generation
bash all/generate_gateway.sh -f test/test.proto -s Message -c test-gateway-image

