#!/bin/bash -e

source ./variables.sh

for build in ${BUILDS[@]}; do
    tag=${CONTAINER}/${build}:${GRPC_VERSION}_${BUILD_VERSION}
    echo "building ${build} container with tag ${tag}"
    docker build -t ${tag} \
        -f Dockerfile \
        --build-arg grpc_version=${GRPC_VERSION} \
        --build-arg grpc_java_version=${GRPC_JAVA_VERSION} \
        --build-arg grpc_web_version=${GRPC_WEB_VERSION} \
        --build-arg grpc_swift_version=${GRPC_SWIFT_VERSION} \
        --build-arg swift_version=${SWIFT_VERSION} \
        --build-arg go_version=${GO_VERSION} \
        --target ${build} \
        .

    if [ "${LATEST}" = true ]; then
        echo "setting ${tag} to latest"
        docker tag ${tag} ${CONTAINER}/${build}:latest
    fi
done
