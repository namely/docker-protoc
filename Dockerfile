FROM debian:jessie
MAINTAINER Core Services <coreservices@namely.com>


RUN apt-get update

# Install Protoc
################
RUN apt-get install -y openssl ca-certificates autoconf automake libtool g++ build-essential git

RUN mkdir -p /mnt/protobufs

WORKDIR /mnt/protobufs

RUN apt-get install -y curl
RUN curl -o protobufs.tar.gz -L https://github.com/google/protobuf/releases/download/v3.0.0-beta-1/protobuf-cpp-3.0.0-beta-1.tar.gz
RUN ["tar", "-zxvf", "./protobufs.tar.gz"]

WORKDIR protobuf-3.0.0-beta-1

RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

# Install libgrpc-dev
RUN git clone https://github.com/grpc/grpc.git /grpc
WORKDIR /grpc
RUN git checkout release-0_11
RUN git submodule update --init

ENV LD_LIBRARY_PATH /usr/local/lib
RUN make
RUN make install

# Setup directories for the volumes that should be used
RUN mkdir /defs
WORKDIR /defs

