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

echo "Building Go source..."
protoc -I /defs /defs/*.proto --go_out=plugins=grpc:.
echo "Done!"
