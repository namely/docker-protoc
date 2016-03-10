#!/bin/bash

set -e

TARGET_DIR="java"

pf=(`find . -maxdepth 1 -name "*.proto"`)
if [ ${#pf[*]} -eq 0 ]; then
  echo "No proto files found!"
  exit 1
fi

echo "Found Proto definitions:"
printf "\t+%s\n" "${pf[@]}"

echo

if [ ! -d "$TARGET_DIR" ]; then
  mkdir $TARGET_DIR
fi

echo "Building java..."
#protoc -I . ${pf[@]} --java_out=./$TARGET_DIR --grpc_out=./$TARGET_DIR --plugin=protoc-gen-grpc=/opt/namely/grpc_java_plugin
protoc --plugin=protoc-gen-grpc-java=/opt/namely/protoc-gen-grpc-java \
    --grpc-java_out=./$TARGET_DIR --proto_path=. ${pf[@]}
echo "Done"
