#!/bin/bash

LANGS=("go" "ruby" "csharp" "java" "python" "objc")

CONTAINER=$1

# Checks that directories were appropriately created, and deletes the generated directory.
testGeneration() {
  lang=$1
  extra_arg=$2
  echo "Testing language $lang $extra_arg"

  # Test calling a file directly.
  docker run --rm -v=`pwd`:/defs $CONTAINER -f test/test.proto -l $lang -i test $extra_arg
  if [[ "$lang" == "python" ]]; then
      if [[ ! -d "gen/pb_$lang" ]]; then
          echo "generated directory does not exist"
          exit 1
       elif [[ ! -f "gen/__init__.py" ]] || [[ ! -f "gen/pb_$lang/__init__.py" ]]; then
          echo "__init__.py files were not generated."
          exit 1
       fi
  elif [[ ! -d "gen/pb-$lang" ]]; then 
      echo "generated directory does not exist"
      exit 1
  fi
  rm -rf gen/

  # Test scanning a dir.
  docker run --rm -v=`pwd`:/defs $CONTAINER -d test -l $lang -o gen/dir/$lang $extra_arg
  if [[ ! -d gen/dir/$lang ]]; then
    echo "generated directory for all-file include method does not exist"
    exit 1
  fi
  rm -rf gen/

  echo "Passed!"
}

# Test grpc-gateway generation.
testGeneration go --with-gateway

# Generate proto files
for lang in ${LANGS[@]}; do
    testGeneration "$lang"
done

# Test grpc-gateway Docker generation
bash generate_gateway.sh -f test/test.proto -s Message -c test-gateway-image

