#!/bin/bash

set -e

TARGET_DIR="pb-python"

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

echo "Building Python..."
python -m grpc.tools.protoc -I . --python_out=./$TARGET_DIR --grpc_python_out=./$TARGET_DIR ${pf[@]}
echo "Done"
