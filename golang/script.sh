#!/bin/sh

set -e

TARGET_DIR="pb-go"

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

echo "Building Go source..."
protoc -I /defs /defs/*.proto --go_out=plugins=grpc:./$TARGET_DIR
echo "Done!"
