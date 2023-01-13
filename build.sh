#!/bin/bash
set -e

source ./variables.sh

for build in ${BUILDS[@]}; do
    tag=${CONTAINER}/${build}:${VERSION}
    echo "building ${build} container with tag ${tag}"
    docker build -t ${tag} \
        -f Dockerfile \
        --build-arg debian_version="${DEBIAN_VERSION}" \
        --build-arg grpc_version="${GRPC_VERSION}" \
        --build-arg grpc_java_version="${GRPC_JAVA_VERSION}" \
        --build-arg grpc_web_version="${GRPC_WEB_VERSION}" \
        --build-arg grpc_gateway_version="${GRPC_GATEWAY_VERSION}" \
        --build-arg go_version="${GO_VERSION}" \
        --build-arg protobuf_js_version="${PROTOBUF_JS_VERSION}" \
        --build-arg uber_prototool_version="${UBER_PROTOTOOL_VERSION}" \
        --build-arg scala_pb_version="${SCALA_PB_VERSION}" \
        --build-arg mypy_version="${MYPY_VERSION}" \
        --build-arg node_version="${NODE_VERSION}" \
        --build-arg node_grpc_tools_node_protoc_ts_version="${NODE_GRPC_TOOLS_NODE_PROTOC_TS_VERSION}" \
        --build-arg node_grpc_tools_version="${NODE_GRPC_TOOLS_VERSION}" \
        --build-arg node_protoc_gen_grpc_web_version="${NODE_PROTOC_GEN_GRPC_WEB_VERSION}" \
        --build-arg go_envoyproxy_pgv_version="${GO_ENVOYPROXY_PGV_VERSION}" \
        --build-arg go_mwitkow_gpv_version="${GO_MWITKOW_GPV_VERSION}" \
        --build-arg ts_proto_version="${TS_PROTO_VERSION}" \
        --build-arg go_protoc_gen_go_version="${GO_PROTOC_GEN_GO_VERSION}" \
        --build-arg go_protoc_gen_go_grpc_version="${GO_PROTOC_GEN_GO_GRPC_VERSION}" \
        --target "${build}" \
        .

    if [ "${LATEST}" = true ]; then
        echo "setting ${tag} to latest"
        docker tag ${tag} ${CONTAINER}/${build}:latest
    fi
done
