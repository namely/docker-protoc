#!/bin/bash -ex

LANGS=("go" "ruby" "csharp" "java" "python" "objc" "node" "gogo" "php" "cpp")

CONTAINER=${CONTAINER}

if [ -z ${CONTAINER} ]; then
    echo "You must specify a build container with \${CONTAINER} to test"
    exit 1
fi

# Checks that directories were appropriately created, and deletes the generated directory.
testGeneration() {
    lang=$1
    shift
    expected_output_dir=$1
    shift
    extra_args=$@
    echo "Testing language $lang $expected_output_dir $extra_args"

    # Test calling a file directly.
    docker run --rm -v=`pwd`:/defs $CONTAINER -f all/test/test.proto -l $lang -i all/test/ $extra_args
    if [[ ! -d "$expected_output_dir" ]]; then 
        echo "generated directory $expected_output_dir does not exist"
        exit 1
    fi

    if [[ "$lang" == "python" ]]; then
        # Test that we have generated the __init__.py files.
        current_path="$expected_output_dir"
        while [[ $current_path != "." ]]; do
          if [[ ! -f "$current_path/__init__.py" ]]; then
              echo "__init__.py files were not generated in $current_path"
              exit 1
          fi
          current_path=$(dirname $current_path)
        done
    fi
    rm -rf `echo $expected_output_dir | cut -d '/' -f1`
    echo "Generating for $lang passed!"
}

# Test grpc-gateway generation (only valid for Go)
testGeneration go "gen/pb-go" --with-gateway

# Generate proto files
for lang in ${LANGS[@]}; do
    expected_output_dir=""
    if [[ "$lang" == "python" ]]; then
        expected_output_dir="gen/pb_$lang"
    else
      expected_output_dir="gen/pb-$lang"
    fi

    # Test without an output directory.
    testGeneration "$lang" "$expected_output_dir"

    # Test with an output directory.
    test_dir="gen/foo/bar"
    testGeneration "$lang" "$test_dir" -o "$test_dir"
done


# Test .jar generation for java
docker run --rm -v=`pwd`:/defs $CONTAINER -f all/test/test.proto -l java -i all/test/ -o gen/test.jar
if [[ ! -f gen/test.jar ]]; then
  echo "Expected gen/test.jar to be a jar file."
  exit 1
fi
