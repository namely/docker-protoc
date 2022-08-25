#!/bin/bash
set -e

source ./variables.sh

for build in ${BUILDS[@]}; do
    tag=${CONTAINER}/${build}:${VERSION}
    echo "pushing ${tag}"
    docker push ${tag}

    if [ "${LATEST}" = true ]; then
        echo "pushing ${tag} as latest"
        docker push ${CONTAINER}/${build}:latest
    fi
done
