#!/bin/sh

set -e

TARGET_DIR="ruby"

if [ ! -f *.proto ]; then
  echo "No proto files found!"
  exit 1
fi

echo "Found Proto definitions:"
for p in *.proto
do
  echo -e "\t+$p"
done

echo 

if [ ! -d "$TARGET_DIR" ]; then
  mkdir $TARGET_DIR
fi

echo "Building..."
protoc -I /defs /defs/*.proto --ruby_out=./$TARGET_DIR --grpc_out=./$TARGET_DIR --plugin=protoc-gen-grpc=/opt/namely/grpc_ruby_plugin

echo "Done"
