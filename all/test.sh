#!/bin/bash -e

LANGS=("go" "ruby" "csharp" "java" "python" "objc" "node" "gogo" "php" "cpp" "descriptor_set" "web")

CONTAINER=${CONTAINER}

if [ -z ${CONTAINER} ]; then
    echo "You must specify a build container with \${CONTAINER} to test"
    exit 1
fi

JSON_PARAM_NAME="additionalParam"

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

    if [[ "$lang" == "go" ]]; then
        # Test that we have generated the test.pb.go file.
        expected_file_name="/all/test.pb.go"
        if [[ "$extra_args" == *"--go-source-relative"* ]]; then
            expected_file_name="/all/test/test.pb.go"
        fi
        if [[ ! -f "$expected_output_dir$expected_file_name" ]]; then
            echo "$expected_file_name file was not generated in $expected_output_dir"
            exit 1
        fi
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
    if [[ "$extra_args" == *"--with-rbi"* ]]; then
        # Test that we have generated the .d.ts files.
        rbi_file_count=$(find $expected_output_dir -type f -name "*.rbi" | wc -l)
        if [ $rbi_file_count -ne 2 ]; then
            echo ".rbi files were not generated in $expected_output_dir"
            exit 1
        fi
    fi
    if [[ "$extra_args" == *"--with-typescript"* ]]; then
        # Test that we have generated the .d.ts files.
        ts_file_count=$(find $expected_output_dir -type f -name "*.d.ts" | wc -l)
        if [ $ts_file_count -ne 2 ]; then
            echo ".d.ts files were not generated in $expected_output_dir"
            exit 1
        fi
    fi

    if [[ "$extra_args" == *"--go-plugin-micro"* ]]; then
        # Test that we have generated the test.pb.micro.go file.
        expected_file_name="/all/test.pb.micro.go"
        if [[ ! -f "$expected_output_dir$expected_file_name" ]]; then
            echo "$expected_file_name file was not generated in $expected_output_dir"
            exit 1
        fi
    fi

    if [[ "$extra_args" == *"--with-gateway"* ]]; then
        # Test that we have generated the test.pb.gw.go file.
        expected_file_name1="/all/test.pb.gw.go"
        expected_file_name2="/all/test/test.swagger.json"
        if [[ ! -f "$expected_output_dir$expected_file_name1" ]]; then
            echo "$expected_file_name1 file was not generated in $expected_output_dir"
            exit 1
        fi
        if [[ ! -f "$expected_output_dir$expected_file_name2" ]]; then
            echo "$expected_file_name2 file was not generated in $expected_output_dir"
            exit 1
        fi

        if [[ "$extra_args" == *"--with-openapi-json-names"* ]]; then
            # Test that we have generated the test.swagger.json file with json params
            if ! grep -q $JSON_PARAM_NAME "$expected_output_dir$expected_file_name2" ; then
                echo "$expected_file_name2 file was not generated with json names"
                exit 1
            fi

            # test that we generated field masks with expected output
            # for the pinned version of grpc-gateway(v2.0.1), we expect the property type to be "array"
            expected_field_mask_property_type="array"
            actual_field_mask_property_type=$(cat $expected_output_dir$expected_file_name2 | jq '.definitions.MessagesUpdateMessageRequest.properties.updateMask.type' | tr -d "\042")
            if [ ! "$actual_field_mask_property_type" == "$expected_field_mask_property_type" ]; then
                echo "expected field mask type not found"
                exit 1
            fi

        elif [[ "$extra_args" == *"--with-swagger-json-names"* ]]; then
            # Test that we have generated the test.swagger.json file with json params
            if ! grep -q $JSON_PARAM_NAME "$expected_output_dir$expected_file_name2" ; then
                echo "$expected_file_name2 file was not generated with json names"
                exit 1
            fi
        fi
    fi

        # Test that we have generated the test.pb.go file.
        expected_file_name="/all/test.pb.go"
    if [[ "$extra_args" == *"--with-validator"* ]]; then
        expected_file_name1="/all/test.pb.go"
        expected_file_name2="/all/test.pb.validate.go"
        if [[ "$extra_args" == *"--validator-source-relative"* ]]; then
            expected_file_name2="/all/test/test.pb.validate.go"
        fi
        if [[ ! -f "$expected_output_dir$expected_file_name1" ]]; then
            echo "$expected_file_name1 file was not generated in $expected_output_dir"
            exit 1
        fi
        if [[ ! -f "$expected_output_dir$expected_file_name2" ]]; then
            echo "$expected_file_name2 file was not generated in $expected_output_dir"
            exit 1
        fi
    fi

    if [[ "$extra_args" == *"--js-out library=testlib"* ]]; then
        # Test that we have generated the testlib.js file
        testlib_count=$(find $expected_output_dir -type f -name "testlib.js" | wc -l)
        if [ $testlib_count -ne 1 ]; then
            echo "testlib.js file was not generated in $expected_output_dir"
            exit 1
        fi
    fi

    if [[ "$extra_args" == *"--grpc-out grpc-js"* ]]; then
        # Test that we have generated the testlib.js file
        testlib_count=$(find $expected_output_dir -type f -name "testlib.js" | wc -l)
        if [ $testlib_count -ne 1 ]; then
            echo "testlib.js file was not generated in $expected_output_dir"
            exit 1
        fi
    fi

    if [[ "$extra_args" == *"--grpc-web-out import_style=commonjs+dts"* ]]; then
        # Test that we have generated the .d.ts files and .js files
        ts_file_count=$(find $expected_output_dir -type f -name "*.d.ts" | wc -l)
        if [ $ts_file_count -ne 2 ]; then
            echo ".d.ts files were not generated in $expected_output_dir"
            exit 1
        fi
        js_file_count=$(find $expected_output_dir -type f -name "*.js" | wc -l)
        if [ $js_file_count -ne 2 ]; then
            echo ".js files were not generated in $expected_output_dir"
            exit 1
        fi
    fi
    if [[ "$extra_args" == *"--grpc-web-out import_style=typescript"* ]]; then
        # Test that we have generated the .d.ts files, .ts files and .js files
        d_ts_file_count=$(find $expected_output_dir -type f -name "*.d.ts" | wc -l)
        if [ $d_ts_file_count -ne 1 ]; then
            echo ".d.ts files were not generated in $expected_output_dir"
            exit 1
        fi
        ts_file_count=$(find $expected_output_dir -type f -name "*Pb.ts" | wc -l)
        if [ $ts_file_count -ne 1 ]; then
            echo ".ts files were not generated in $expected_output_dir"
            exit 1
        fi
        js_file_count=$(find $expected_output_dir -type f -name "*.js" | wc -l)
        if [ $js_file_count -ne 1 ]; then
            echo "More than 1 .js file was generated in $expected_output_dir"
            exit 1
        fi
    fi

    rm -rf `echo $expected_output_dir | cut -d '/' -f1`
    echo "Generating for $lang passed!"
}

# Test grpc-gateway generation (only valid for Go)
testGeneration go "gen/pb-go" --with-gateway

# Test grpc-gateway generation + json (only valid for Go)
testGeneration go "gen/pb-go" --with-gateway --with-openapi-json-names

# Test grpc-gateway generation + json (deprecated) (only valid for Go)
testGeneration go "gen/pb-go" --with-gateway --with-swagger-json-names

# Test go source relative generation
testGeneration go "gen/pb-go" --go-source-relative

# Test go validator
testGeneration go "gen/pb-go" --with-validator

# Test go validator with source relative option
testGeneration go "gen/pb-go" --with-validator --validator-source-relative

# Test go-micro generations
testGeneration go "gen/pb-go" --go-plugin-micro

# Test Sorbet RBI declaration file generation (only valid for Ruby)
testGeneration ruby "gen/pb-ruby" --with-rbi

# Test TypeScript declaration file generation (only valid for Node)
testGeneration node "gen/pb-node" --with-typescript

# Test node alternative import style (only valid for node and web)
testGeneration node "gen/pb-node" --js-out library=testlib

# Test node grpc-out alternative import style (only valid for node and web)
testGeneration node "gen/pb-node" --grpc-out grpc-js

# Test grpc web alternative import style (only valid for web)
testGeneration web "gen/pb-web" --grpc-web-out import_style=typescript
testGeneration web "gen/pb-web" --grpc-web-out import_style=commonjs+dts

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
