#!/bin/bash

set -e

TARGET_DIR="pb-php"

pf=(`find . -maxdepth 1 -name "*.proto"`)
if [ ${#pf[@]} -eq 0 ]; then
  echo "No proto files found!"
  exit 1
fi

echo "Found Proto definitions:"
printf "\t+%s\n" "${pf[@]}"

echo 

if [ ! -d "$TARGET_DIR" ]; then
  mkdir $TARGET_DIR
fi

echo "Building Go source..."
protoc -I . ${pf[@]} --plugin=/root/.composer/vendor/protocolbuffers/protoc-gen-php/bin/protoc-gen-php --php_out=plugins=grpc:./$TARGET_DIR
echo "Done!"
