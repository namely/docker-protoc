#!/bin/bash

set -e

TARGET_DIR="ruby"

pf=(`find . -maxdepth 1 -name "*.proto"`)
if [ ${#pf[*]} -eq 0 ]; then
  echo "No proto files found!"
  exit 1
fi

echo "Found Proto definitions:"
for p in ${pf[@]}
do
  echo -e "\t+$p"
done

if [ ! -d "$TARGET_DIR" ]; then
  mkdir $TARGET_DIR
fi

echo "Building Ruby..."
protoc -I /defs /defs/*.proto --ruby_out=./$TARGET_DIR --grpc_out=./$TARGET_DIR --plugin=protoc-gen-grpc=/opt/namely/grpc_ruby_plugin

echo "Done"
