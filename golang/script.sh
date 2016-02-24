#!/bin/bash

set -e

TARGET_DIR="pb-go"

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

echo 

if [ ! -d "$TARGET_DIR" ]; then
  mkdir $TARGET_DIR
fi

echo "Building Go source..."
#protoc -I /defs /defs/*.proto --go_out=plugins=grpc:./$TARGET_DIR
protoc -I . ./*.proto --go_out=plugins=grpc:./$TARGET_DIR
echo "Done!"
