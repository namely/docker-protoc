#!/usr/bin/env bash

set -e

echo "Building Docker containers"

declare -a DIRS=( 'golang' 'ruby' 'python' )
declare -a IMAGES=( 'protoc-go' 'protoc-ruby' 'protoc-python' )

GOLANG_IMAGE='protoc-go'
RUBY_IMAGE='protoc-ruby'
PYTHON_IMAGE='protoc-python'

REGISTRY='namely'
BASE_IMAGE='protoc'
TAG=$(git rev-parse --short HEAD)
TAG='latest'

buildAll () {
  docker build -t $REGISTRY/$BASE_IMAGE:$TAG .
  for i in ${!IMAGES[@]};
  do
    echo
    echo "Building ${IMAGES[$i]}... "
    docker build -t $REGISTRY/${IMAGES[$i]}:$TAG ./${DIRS[$i]}
  done
}

#Read from args
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -t|--tag)
      TAG=$2
      shift
      ;;
    *)
      ;;
  esac
  shift
done

buildAll

echo "Done!"
