FROM alpine:latest
MAINTAINER Core Services <coreservices@namely.com>

# Install Protoc
################
RUN apk add --update openssl ca-certificates autoconf automake libtool g++ make

RUN mkdir -p /mnt/protobufs

WORKDIR /mnt/protobufs

RUN wget https://github.com/google/protobuf/releases/download/v3.0.0-beta-1/protobuf-cpp-3.0.0-beta-1.tar.gz
RUN tar -zxvf protobuf-cpp-3.0.0-beta-1.tar.gz

WORKDIR protobuf-3.0.0-beta-1
RUN ls -lsa

RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

# Setup directories for the volumes that should be used
RUN mkdir /defs
WORKDIR /defs

