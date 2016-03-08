#!/usr/bin/env bash

set -e

echo "Building Docker containers"

REGISTRY='namely'
BASE_IMAGE='protoc'
GOLANG_IMAGE='protoc-go'
RUBY_IMAGE='protoc-ruby'
TAG=$(git rev-parse --short HEAD)
TAG='latest'

buildAll () {
  docker build -t $REGISTRY/$BASE_IMAGE:$TAG .
  docker build -t $REGISTRY/$RUBY_IMAGE:$TAG ./ruby
  docker build -t $REGISTRY/$GOLANG_IMAGE:$TAG ./golang
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
