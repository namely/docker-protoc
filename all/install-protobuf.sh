#!/bin/sh

if [ -z $1 ]; then
    echo "You must specify a grpc version."
    exit 1
fi

git clone -b v$1.x --recursive -j8 https://github.com/grpc/grpc
cd /tmp/grpc
make
make install
# php support
git submodule update --init
make grpc_php_plugin

cp /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/

cd /tmp/grpc/third_party/protobuf
make
make install

cd /tmp
git clone -b v$1.x --recursive https://github.com/grpc/grpc-java.git
cd /tmp/grpc-java/compiler
../gradlew java_pluginExecutable
