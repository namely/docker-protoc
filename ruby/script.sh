#!/bin/sh

set -e

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

echo "Building..."
protoc -I /defs /defs/*.proto --ruby_out=./ruby --grpc_out=./ruby --plugin=protoc-gen-grpc=/opt/namely/grpc_ruby_plugin

echo "Done"
