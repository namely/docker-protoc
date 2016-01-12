#!/bin/sh

if [ ! -f *.proto ]; then
  echo "No proto files found!"
  exit 1
fi

echo "Found Proto definitions:"
ls *.proto

echo "Building..."
#protoc -I /defs /defs/*.proto --ruby_out=./ --grpc_out=./ --plugin=protoc-gen-grpc=`which grpc_ruby_plugin`
protoc -I /defs /defs/*.proto --ruby_out=./ --grpc_out=./ --plugin=protoc-gen-grpc=/opt/namely/grpc_ruby_plugin

echo "Done"
