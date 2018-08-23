#!/bin/bash

source ./variables.sh

for build in ${BUILDS[@]}; do
    tag=${CONTAINER}/${build}:${GRPC_VERSION}_${BUILD_VERSION}
    echo "building ${build} container with tag ${tag}"
	docker build -t ${tag} \
        -f Dockerfile \
        --build-arg grpc=${GRPC_VERSION} \
        --target ${build} \
        .

    if [ "${LATEST}" = true ]; then
        echo "setting ${tag} to latest"
        docker tag ${tag} ${CONTAINER}/${build}:latest
    fi
done
