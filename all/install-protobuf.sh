#!/bin/sh

GRPC_VERSION=v1.7.x

## Install gflags for grpc_cli
cd /tmp
git clone https://github.com/gflags/gflags.git
cd gflags && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=1 -DGFLAGS_INSTALL_SHARED_LIBS=1 .. && \
    make install

## Install grpc
cd /tmp
git clone -b $GRPC_VERSION --recursive -j8 https://github.com/grpc/grpc
cd /tmp/grpc
make 
make install
make grpc_cli

## Make protoc and grpc_cli available
cp /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
cp /tmp/grpc/bins/opt/grpc_cli /usr/local/bin/

## Install protobuf libraries
cd /tmp/grpc/third_party/protobuf
make
make install

## Install grpc-java plugin
cd /tmp
git clone -b $GRPC_VERSION --recursive https://github.com/grpc/grpc-java.git
cd /tmp/grpc-java/compiler
../gradlew java_pluginExecutable
