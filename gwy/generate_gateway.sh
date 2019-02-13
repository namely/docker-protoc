#!/bin/bash

set -e

printUsage() {
  echo "protoc-gen-gwy generates a ready-to-build gRPC gateway server."
  echo ""
  echo "Options:"
  echo "-h, --help              Show this message."
  echo "-i, --includes INCLUDES Extra includes (optional)."
  echo "-f, --file FILE         Relative path to the proto file to build the gateway from."
  echo "-s, --service SERVICE   The name of the service to build the gateway for."
  echo "-o, --out DIRECTORY     Optional. The output directory for the gateway. By default, gen/grpc-gateway."
}

# Path to the proto file
FILE=""
# Name of the service.
SERVICE=""
# Output directory.
OUT_DIR=""
# Extra includes.
INCLUDES=""

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      printUsage
      exit 0
      ;;
    -i|--includes)
      shift
      if test $# -gt 0; then
        INCLUDES="$INCLUDES -i $1"
        shift
      else
        echo "Missing extra include directory name for --includes."
        echo ""
        printUsage
        exit 1
      fi
      ;;
    -f|--file)
      shift
      if test $# -gt 0; then
        FILE=$1
        shift
      else
        echo "Missing file name for --file."
        echo ""
        printUsage
        exit 1
      fi
      ;;
    -s|--service)
      shift
      if test $# -gt 0; then
        SERVICE=$1
        shift
      else
        echo "Missing service name for --service."
        echo ""
        printUsage
        exit 1
      fi
      ;;
    -o|--out)
      shift
      if test $# -gt 0; then
        OUT_DIR=$1
        shift
      else
        echo "Missing output directory for --out"
        echo ""
        printUsage
        exit 1
      fi
      ;;
    *)
      printUsage
      exit 1
      ;;
  esac
done

if [[ -z $FILE ]]; then
  echo "Error: You must specify the proto file name"
  printUsage
  exit 1
fi

if [[ -z $SERVICE ]]; then
  echo "Error: You must specify the proto service name"
  printUsage
  exit 1
fi

if [[ -z $OUT_DIR ]]; then
  OUT_DIR="./gen/grpc-gateway"
fi

# Generate the gateway files in src
PROTO_DIR=$(dirname $FILE)
entrypoint.sh -d $PROTO_DIR -l go --with-gateway -o $OUT_DIR/src/gen/pb-go $INCLUDES

# Find the Swagger file.
PROTO_FILE=$(basename $FILE)
SWAGGER_FILE_NAME=`basename $PROTO_FILE .proto`.swagger.json

# Copy and update the templates.
sed -e "s/\${SWAGGER_FILE_NAME}/${SWAGGER_FILE_NAME}/g" \
  /templates/config.yaml.tmpl \
  > $OUT_DIR/config.yaml

sed -e "s/\${SWAGGER_FILE_NAME}/${SWAGGER_FILE_NAME}/g" \
  /templates/Dockerfile.tmpl \
  > $OUT_DIR/Dockerfile

MAIN_DIR=$OUT_DIR/src/pkg/main
mkdir -p $MAIN_DIR
sed -e "s/\${SERVICE}/${SERVICE}/g" \
  /templates/main.go.tmpl \
  > $MAIN_DIR/main.go

