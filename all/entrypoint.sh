#!/bin/bash

set -e

printUsage() {
    echo "gen-proto generates grpc and protobuf @ Namely"
    echo " "
    echo "Usage: gen-proto -f my-service.proto -l go"
    echo " "
    echo "options:"
    echo " -h, --help           Show help"
    echo " -f FILE              The proto source file to generate"
    echo " -l LANGUAGE          The language to generate (${SUPPORTED_LANGUAGES[@]})"
    echo " -o DIRECTORY         The output directory for generated files. Will be automatically created."
    echo " -i includes          Extra includes"
    echo " --with-gateway       Generate grpc-gateway files (experimental)."

}

GEN_GATEWAY=false
SUPPORTED_LANGUAGES=("go" "ruby" "csharp" "java" "python" "objc")
GEN_DIR="./gen"
EXTRA_INCLUDES=""
OUT_DIR=""

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            printUsage
            exit 0
            ;;
        -f)
            shift
            if test $# -gt 0; then
                FILE=$1
            else
                echo "no input file specified"
                exit 1
            fi
            shift
            ;;
        -l)
            shift
            if test $# -gt 0; then
                GEN_LANG=$1
            else
                echo "no language specified"
                exit 1
            fi
            shift
            ;;
        -o) shift
            OUT_DIR=$1
            shift
            ;;
        -i) shift
            EXTRA_INCLUDES="-I$1"
            shift
            ;;
        --with-gateway)
            GEN_GATEWAY=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ -z $FILE ]; then
    echo "Error: You must specify a proto file"
    printUsage
    exit 1
fi

if [ -z $GEN_LANG ]; then
    echo "Error: You must specify a language: ${SUPPORTED_LANGUAGES[@]}"
    printUsage
    exit 1
fi

if [[ ! ${SUPPORTED_LANGUAGES[*]} =~ "$GEN_LANG" ]]; then
    echo "Language $GEN_LANG is not supported. Please specify one of: ${SUPPORTED_LANGUAGES[@]}"
    exit 1
fi

PLUGIN_LANG=$GEN_LANG
if [ $PLUGIN_LANG == 'objc' ] ; then
    PLUGIN_LANG='objective_c'
fi

if [[ $OUT_DIR == '' ]]; then
    OUT_DIR="${GEN_DIR}/pb-$GEN_LANG"
fi

echo "Generting $GEN_LANG files for $FILE in $OUT_DIR"

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

GEN_STRING=''
case $GEN_LANG in
    "go") 
        GEN_STRING="--go_out=plugins=grpc:$OUT_DIR"
        ;;
    "java")
        GEN_STRING="--grpc_out=$OUT_DIR --${GEN_LANG}_out=$OUT_DIR --plugin=protoc-gen-grpc=`which protoc-gen-grpc-java`"
        ;;
    *)
        GEN_STRING="--grpc_out=$OUT_DIR --${GEN_LANG}_out=$OUT_DIR --plugin=protoc-gen-grpc=`which grpc_${PLUGIN_LANG}_plugin`"
        ;;
esac

PROTO_INCLUDE="-I . \
    -I /usr/include/ \
    -I /usr/local/include/ \
    $EXTRA_INCLUDES"

protoc $PROTO_INCLUDE \
    $GEN_STRING \
    $FILE

if [ $GEN_GATEWAY = true ]; then
    mkdir -p ${GEN_DIR}/pb-go
    protoc $PROTO_INCLUDE \
		--grpc-gateway_out=logtostderr=true:$OUT_DIR \
        $FILE
	protoc $PROTO_INCLUDE  \
		--swagger_out=logtostderr=true:$OUT_DIR \
        $FILE 
fi