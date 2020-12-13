ARG debian=buster
ARG go=1.14
ARG grpc
ARG grpc_java
ARG buf_version
ARG grpc_web

FROM golang:$go-$debian AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc
ARG grpc_java
ARG grpc_web
ARG buf_version

RUN set -ex && apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    cmake \
    curl \
    git \
    openjdk-11-jre \
    unzip \
    libtool \
    autoconf \
    zlib1g-dev    \
    libssl-dev

WORKDIR /tmp

RUN git clone -b v$grpc.x --recursive -j8 --depth 1 https://github.com/grpc/grpc
RUN mkdir -p /tmp/grpc/cmake/build
WORKDIR /tmp/grpc/cmake/build
RUN cmake ../..  \
    -DCMAKE_BUILD_TYPE=Release \
    -DgRPC_INSTALL=ON \
    -DgRPC_BUILD_TESTS=OFF \
    -DgRPC_ZLIB_PROVIDER=package \
    -DgRPC_SSL_PROVIDER=package \
    -DCMAKE_INSTALL_PREFIX=/opt
RUN make
RUN make install

# update path for go get dependencies
ENV PATH "$PATH:/opt/bin"

# Workaround for the transition to protoc-gen-go-grpc
# https://grpc.io/docs/languages/go/quickstart/#regenerate-grpc-code
WORKDIR /tmp
RUN git clone -b v$grpc.x --recursive https://github.com/grpc/grpc-go.git
RUN ( cd ./grpc-go/cmd/protoc-gen-go-grpc && go install . )

WORKDIR /tmp
RUN git clone -b v$grpc_java.x --recursive https://github.com/grpc/grpc-java.git
WORKDIR /tmp/grpc-java/compiler
RUN CXXFLAGS="-I/opt/include" LDFLAGS="-L/opt/lib" ../gradlew -PskipAndroid=true java_pluginExecutable

WORKDIR /tmp

# Install Buf
RUN BIN="/usr/local/bin" && \
    BINARY_NAME="buf" && \
    curl -sSL \
    "https://github.com/bufbuild/buf/releases/download/v"$buf_version"/${BINARY_NAME}-$(uname -s)-$(uname -m)" \
    -o "${BIN}/${BINARY_NAME}" && \
    chmod +x "${BIN}/${BINARY_NAME}"

# Go get go-related bins
RUN go get -u google.golang.org/grpc
RUN go get -u google.golang.org/protobuf/cmd/protoc-gen-go

# Gogo and Gogo Fast
RUN go get -u github.com/gogo/protobuf/protoc-gen-gogo
RUN go get -u github.com/gogo/protobuf/protoc-gen-gogofast

# Lint
RUN go get -u github.com/ckaznocha/protoc-gen-lint

# Docs
RUN go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

# Figure out if this is a naming collision
# RUN go get -u github.com/micro/protobuf/protoc-gen-go

RUN go get -d github.com/envoyproxy/protoc-gen-validate
RUN make -C /go/src/github.com/envoyproxy/protoc-gen-validate/ build

# Omniproto
RUN go get -u github.com/grpckit/omniproto

# Add Ruby Sorbet types support (rbi)
RUN go get -u github.com/coinbase/protoc-gen-rbi

# Add scala support
RUN curl -LO https://github.com/scalapb/ScalaPB/releases/download/v0.9.6/protoc-gen-scala-0.9.6-linux-x86_64.zip \
    && unzip protoc-gen-scala-0.9.6-linux-x86_64.zip \
    && chmod +x /tmp/protoc-gen-scala

# Add grpc-web support
RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${grpc_web}/protoc-gen-grpc-web-${grpc_web}-linux-x86_64 \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

FROM debian:$debian-slim AS grpckit

RUN mkdir -p /usr/share/man/man1
RUN set -ex && apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    nodejs \
    npm \
    zlib1g \
    libssl1.1 \
    openjdk-11-jre

WORKDIR /workspace

# Add TypeScript support
RUN npm config set unsafe-perm true
RUN npm i -g ts-protoc-gen@0.12.0

COPY --from=build /opt/bin/ /usr/local/bin/
COPY --from=build /opt/include/ /usr/local/include/
COPY --from=build /opt/lib/ /usr/local/lib/
COPY --from=build /opt/share/ /usr/local/share/
COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /go/bin/ /usr/local/bin/
COPY --from=build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin
COPY --from=build /usr/local/bin/buf /usr/local/bin/buf
COPY --from=build /tmp/protoc-gen-scala /usr/local/bin/

# NB(MLH) We shouldn't need to copy these to include, as protofiles should be sourced elsewhere
# COPY --from=build /go/src/github.com/envoyproxy/protoc-gen-validate/ /opt/include/github.com/envoyproxy/protoc-gen-validate/
# COPY --from=build /go/src/github.com/mwitkow/go-proto-validators/ /opt/include/github.com/mwitkow/go-proto-validators/

# protoc
FROM grpckit AS protoc
ENTRYPOINT [ "protoc" ]

# buf
FROM grpckit AS buf
ENTRYPOINT [ "buf" ]

# omnikit
FROM grpckit AS omniproto
ENTRYPOINT [ "omniproto" ]

FROM grpckit
