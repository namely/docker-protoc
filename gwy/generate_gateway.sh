#!/bin/bash

set -e

printUsage() {
  echo "protoc-gen-gwy generates a ready-to-build gRPC gateway server."
  echo ""
  echo "Options:"
  echo "-h, --help                  Show this message."
  echo "-i, --includes INCLUDES     Extra includes (optional)."
  echo "-f, --file FILE             Relative path to the proto file to build the gateway from."
  echo "-s, --service SERVICE       The name of the service to build the gateway for."
  echo "-a, --additional_interfaces The set of additional interfaces to bind to this gateway." 
  echo "-o, --out DIRECTORY         Optional. The output directory for the gateway. By default, gen/grpc-gateway."
}

# Path to the proto file
FILE=""
# Name of the service.
SERVICE=""
# Name of additional interfaces
ADDITIONAL_INTERFACES=""
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
    -a|--additional_interfaces)
      shift
      if test $# -gt 0; then
        ADDITIONAL_INTERFACES=$1
        shift
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
OUT_PATH=$OUT_DIR/src/gen/pb-go
entrypoint.sh -d $PROTO_DIR -l go --with-gateway -o $OUT_PATH $INCLUDES

GATEWAY_IMPORT_DIR=`find $OUT_PATH -type f -name "*.gw.go" -print | head -n 1 | xargs -n1 dirname`
GATEWAY_IMPORT_DIR=${GATEWAY_IMPORT_DIR#"$OUT_DIR/src/"}

# Find the Swagger file.
PROTO_FILE=$(basename $FILE)
SWAGGER_FILE_NAME=`basename $PROTO_FILE .proto`.swagger.json

# Copy and update the templates.
renderizer --import=${GATEWAY_IMPORT_DIR} --swagger=${SWAGGER_FILE_NAME} /templates/config.yaml.tmpl > $OUT_DIR/config.yaml
renderizer --import=${GATEWAY_IMPORT_DIR} --swagger=${SWAGGER_FILE_NAME} /templates/Dockerfile.tmpl > $OUT_DIR/Dockerfile

MAIN_DIR=$OUT_DIR/src/pkg/main
mkdir -p $MAIN_DIR
renderizer --import=${GATEWAY_IMPORT_DIR} --service=${SERVICE} --additional=${ADDITIONAL_INTERFACES} /templates/main.go.tmpl > $MAIN_DIR/main.go

