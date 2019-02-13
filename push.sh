#!/bin/bash -ex

source ./variables.sh

for build in ${BUILDS[@]}; do
    tag=${CONTAINER}/${build}:${GRPC_VERSION}_${BUILD_VERSION}
    echo "pushing ${tag}"
    docker push ${tag}

    if [ "${LATEST}" = true ]; then
        echo "pushing ${tag} as latest"
        docker push ${CONTAINER}/${build}:latest
    fi
done
