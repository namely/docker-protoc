#!/bin/sh

if [ ! -f *.proto ]; then
  echo "No proto files found!"
  exit 1
fi

echo "Found Proto definitions:"
ls *.proto

echo "Building..."
protoc -I /defs /defs/*.proto --go_out=plugins=grpc:.
echo "Done"
