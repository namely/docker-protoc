#!/bin/bash

set -e

printUsage() {
    echo "gen-proto generates grpc and protobuf @ Namely"
    echo " "
    echo "Usage: gen-proto -f my-service.proto -l go"
    echo " "
    echo "options:"
    echo " -h, --help           show help"
    echo " -f FILE              the proto source file to generate"
    echo " -l LANGUAGE          the language to generate (${SUPPORTED_LANGUAGES[@]})"
    #echo " --with-gateway       generate grpc-gateway sidecar"
}

GEN_GATEWAY=false
SUPPORTED_LANGUAGES=("go" "ruby" "csharp" "node" "java" "python" "objc")
GEN_DIR="./gen"
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
        --with-gateway)
            GEN_GATEWAY=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

echo "Generting $GEN_LANG files for $FILE"

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

if [ $GEN_LANG == 'objc' ] ; then
    GEN_LANG='objective_c'
fi

if [[ ! -d "${GEN_DIR}/pb-$GEN_LANG" ]]; then
  mkdir -p "${GEN_DIR}/pb-$GEN_LANG"
fi

GEN_STRING=''
case $GEN_LANG in
    "go") 
        GEN_STRING="--go_out=plugins=grpc:${GEN_DIR}/pb-$GEN_LANG"
        ;;
    "java")
        GEN_STRING="--grpc_out=${GEN_DIR}/pb-$GEN_LANG --${GEN_LANG}_out=${GEN_DIR}/pb-$GEN_LANG --plugin=protoc-gen-grpc=`which protoc-gen-grpc-java`"
        ;;
    *)
        GEN_STRING="--grpc_out=${GEN_DIR}/pb-$GEN_LANG --${GEN_LANG}_out=${GEN_DIR}/pb-$GEN_LANG --plugin=protoc-gen-grpc=`which grpc_${GEN_LANG}_plugin`"
        ;;
esac

protoc -I . \
    -I /usr/include/ \
    $GEN_STRING \
    $FILE
