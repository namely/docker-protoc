#!/bin/bash -e

DOCKER_REPO=${DOCKER_REPO}
NAMESPACE=${NAMESPACE:-namely}
GRPC_VERSION=${GRPC_VERSION:-1.34}
GRPC_JAVA_VERSION=${GRPC_JAVA_VERSION:-1.34}
GRPC_WEB_VERSION=${GRPC_WEB_VERSION:-1.2.1}
GRPC_GATEWAY_VERSION=${GRPC_GATEWAY_VERSION:-2.0.1}
GO_VERSION=${GO_VERSION:-1.14}
BUILD_VERSION=${BUILD_VERSION:-1}
CONTAINER=${DOCKER_REPO}${NAMESPACE}
LATEST=${1:false}
BUILDS=("protoc-all" "protoc" "prototool" "grpc-cli" "gen-grpc-gateway")
