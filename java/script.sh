#!/bin/bash

set -e

TARGET_DIR="pb-java"

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
protoc --plugin=protoc-gen-grpc-java=/opt/namely/protoc-gen-grpc-java \
    --grpc-java_out=./$TARGET_DIR --proto_path=. ${pf[@]}
echo "Done"
