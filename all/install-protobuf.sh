#!/bin/bash -e

if [ -z $1 ]; then
    echo "You must specify a grpc version."
    exit 1
fi

if [ -z $2 ]; then
    echo "You must specify a grpc-java version."
    exit 1
fi

curl -sSL https://github.com/gflags/gflags/archive/v2.2.1.tar.gz -o gflags.tar.gz && tar -xzvf gflags.tar.gz
cd gflags-2.2.1/
cmake .
make
make install

cd /tmp

git clone -b v$1.x --recursive -j8 --depth 1 https://github.com/grpc/grpc
mkdir -p /tmp/grpc/cmake/build
cd /tmp/grpc/cmake/build
# gRPC_BUILD_TESTS for grpc_cli - very slow
cmake ../..                      \
    -DgRPC_INSTALL=ON            \
    -DgRPC_ZLIB_PROVIDER=package \
    -DgRPC_SSL_PROVIDER=package  \
    -DCMAKE_INSTALL_PREFIX=/opt  \
	-DBUILD_TESTING=OFF          \
	-DgRPC_BUILD_TESTS=ON
RUN make
RUN make install

# Workaround for the transition to protoc-gen-go-grpc
# https://grpc.io/docs/languages/go/quickstart/#regenerate-grpc-code
cd /tmp
git clone -b v$grpc.x --recursive https://github.com/grpc/grpc-go.git
( cd ./grpc-go/cmd/protoc-gen-go-grpc && go install . )

# php support
git submodule update --init
make grpc_php_plugin

cp /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/

cd /tmp/grpc/third_party/protobuf
make
make install

cd /tmp/grpc/third_party/protobuf
./autogen.sh
cd /tmp/grpc
make grpc_cli

cd /tmp
git clone -b v$2.x --recursive https://github.com/grpc/grpc-java.git
cd /tmp/grpc-java/compiler
../gradlew -PskipAndroid=true java_pluginExecutable
