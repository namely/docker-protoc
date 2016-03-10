#!/usr/bin/env bash

set -e

echo "Building Docker containers"

declare -a IMAGES
DIRS=( $(basename $(find . ! -path . -type d -not -path '*/\.*')) )

REGISTRY='namely'
BASE_IMAGE='protoc'
TAG=$(git rev-parse --short HEAD)
TAG='latest'

buildAll () {
  docker build -t $REGISTRY/$BASE_IMAGE:$TAG .
  for i in ${!DIRS[@]};
  do
    echo
    echo "Building ${DIRS[$i]}... "
    IMAGE=$REGISTRY/$BASE_IMAGE-${DIRS[$i]}:$TAG
    docker build -t $IMAGE ./${DIRS[$i]}
    IMAGES+=( $IMAGE )
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
