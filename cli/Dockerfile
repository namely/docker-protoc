# Build a Debian based image with grpc_cli as the entrypoint.
#
# Suppose you have a gRPC service running on your laptop at localhost:50051. Call it in
# grpc_cli:
# 
# docker run -v `pwd`:/defs --rm -it test-grpc-cli call docker.for.mac.localhost:50051
#   LinkShortener.ResolveShortLink "short_link:'asdf'" --protofiles=link_shortener.proto
#
# Note the address - since grpc_cli is running on the host machine, localhost won't work.
# Docker for Mac provides the special docker.for.mac.localhost DNS address that resolves
# to the host machine's IP.
#
# The user should mount their `pwd` to /defs.

from debian:stretch-slim AS build

RUN apt-get update
RUN apt-get install -y git libgflags-dev build-essential automake autoconf libtool shtool curl unzip
WORKDIR /tmp
RUN git clone https://github.com/grpc/grpc

WORKDIR /tmp/grpc
RUN git submodule update --init

# Build grpc_cli
# For some reason, we have to do this manually.
WORKDIR /tmp/grpc/third_party/protobuf
RUN ./autogen.sh

WORKDIR /tmp/grpc
RUN make grpc_cli

# Grab standard proto libraries
WORKDIR /tmp
RUN git clone https://github.com/google/protobuf.git
RUN git clone https://github.com/googleapis/googleapis
RUN git clone https://github.com/grpc-ecosystem/grpc-gateway


# Build release image
FROM debian:stretch-slim
RUN apt-get update

# grpc_cli requires libgflags-dev
RUN apt-get install -y libgflags-dev
RUN apt-get clean
# Remove cached lists
RUN rm -rf /var/lib/apt/lists/*

# Copy grpc_cli binary
COPY --from=build /tmp/grpc/bins/opt/grpc_cli /bin/grpc_cli

# Copy standard proto files
COPY --from=build /tmp/protobuf/src/google/protobuf/*.proto /protos/google/protobuf/
COPY --from=build /tmp/googleapis/google/api /protos/google/api
COPY --from=build /tmp/grpc-gateway/protoc-gen-swagger/options /protos/protoc-gen-swagger/options

COPY entrypoint.sh /

WORKDIR /run
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
