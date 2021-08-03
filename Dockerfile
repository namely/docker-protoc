ARG debian=buster
ARG go_version
ARG grpc_version
ARG grpc_gateway_version
ARG grpc_java_version
ARG uber_prototool_version
ARG scala_pb_version
ARG node_version
ARG node_grpc_tools_node_protoc_ts_version 
ARG node_grpc_tools_version
ARG node_protoc_gen_grpc_web_version
ARG buf_cli_version

FROM golang:$go_version-$debian AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc_version
ARG grpc_gateway_version
ARG grpc_java_version
ARG grpc_web_version
ARG scala_pb_version
ARG buf_cli_version

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
    zlib1g-dev \
    libssl-dev \
    clang

WORKDIR /tmp
RUN git clone --depth 1 --shallow-submodules -b v$grpc_version.x --recursive https://github.com/grpc/grpc && \ 
    git clone --depth 1 --shallow-submodules -b v$grpc_java_version.x --recursive https://github.com/grpc/grpc-java.git && \
    git clone --depth 1 --shallow-submodules -b v$grpc_version.x --recursive https://github.com/grpc/grpc-go.git && \
    git clone --depth 1 https://github.com/googleapis/googleapis && \
    git clone --depth 1 https://github.com/googleapis/api-common-protos

ARG bazel=/tmp/grpc/tools/bazel

WORKDIR /tmp/grpc
RUN $bazel build //external:protocol_compiler && \
    $bazel build //src/compiler:all && \
    $bazel build //test/cpp/util:grpc_cli

WORKDIR /tmp/grpc-java
RUN $bazel build //compiler:grpc_java_plugin

WORKDIR /tmp
# Install protoc required by envoyproxy/protoc-gen-validate package
RUN cp -a /tmp/grpc/bazel-bin/external/com_google_protobuf/. /usr/local/bin/
# Copy well known proto files required by envoyproxy/protoc-gen-validate package
RUN mkdir -p /usr/local/include/google/protobuf && \
    cp -a /tmp/grpc/bazel-grpc/external/com_google_protobuf/src/google/protobuf/. /usr/local/include/google/protobuf/

WORKDIR /tmp
RUN curl -sSL https://github.com/uber/prototool/releases/download/v${uber_prototool_version}/prototool-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/prototool && \
    chmod +x /usr/local/bin/prototool

# Workaround for the transition to protoc-gen-go-grpc
# https://grpc.io/docs/languages/go/quickstart/#regenerate-grpc-code
RUN ( cd ./grpc-go/cmd/protoc-gen-go-grpc && go install . )

# Go get go-related bins
WORKDIR /tmp
RUN go get -u google.golang.org/grpc

# install protoc-gen-grpc-gateway and protoc-gen-openapiv2
RUN set -e && \
    GO111MODULE=on go get -u github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v${grpc_gateway_version} && \
    cd /go/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/v2@v${grpc_gateway_version}/protoc-gen-grpc-gateway && \
    go install .

RUN set -e && \
    GO111MODULE=on go get -u github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v${grpc_gateway_version} && \
    cd /go/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/v2@v${grpc_gateway_version}/protoc-gen-openapiv2 && \
    go install .

RUN go get -u github.com/gogo/protobuf/protoc-gen-gogo
RUN go get -u github.com/gogo/protobuf/protoc-gen-gogofast

RUN go get -u github.com/ckaznocha/protoc-gen-lint
RUN go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

RUN go get -u github.com/micro/micro/cmd/protoc-gen-micro

RUN go get -d github.com/envoyproxy/protoc-gen-validate
RUN make -C /go/src/github.com/envoyproxy/protoc-gen-validate/ build

RUN go get -u github.com/mwitkow/go-proto-validators/protoc-gen-govalidators

# Add Ruby Sorbet types support (rbi)
RUN go get -u github.com/coinbase/protoc-gen-rbi

RUN go get github.com/gomatic/renderizer/cmd/renderizer

# Origin protoc-gen-go should be installed last, for not been overwritten by any other binaries(see #210)
RUN go get -u github.com/golang/protobuf/protoc-gen-go

# Add scala support
RUN curl -LO https://github.com/scalapb/ScalaPB/releases/download/v${scala_pb_version}/protoc-gen-scala-${scala_pb_version}-linux-x86_64.zip \ 
    && unzip protoc-gen-scala-${scala_pb_version}-linux-x86_64.zip \
    && chmod +x /tmp/protoc-gen-scala

# Add grpc-web support
RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${grpc_web_version}/protoc-gen-grpc-web-${grpc_web_version}-linux-x86_64 \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

# Add buf support
RUN curl -sSL https://github.com/bufbuild/buf/releases/download/v${buf_cli_version}/buf-Linux-x86_64 \
    -o /tmp/buf && \
    chmod +x /tmp/buf

FROM debian:$debian-slim AS protoc-all

ARG grpc_version
ARG grpc_gateway_version

ARG node_version
ARG node_grpc_tools_node_protoc_ts_version
ARG node_grpc_tools_version
ARG node_protoc_gen_grpc_web_version

RUN mkdir -p /usr/share/man/man1
RUN set -ex && apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    software-properties-common \
    ca-certificates \
    zlib1g \
    libssl1.1 \
    openjdk-11-jre \
    dos2unix \
    gawk

# Install latest Node version
RUN curl -fsSL https://deb.nodesource.com/setup_${node_version}.x | bash -
RUN apt-get install -y nodejs

# Add TypeScript support
RUN npm config set unsafe-perm true
RUN npm i -g grpc_tools_node_protoc_ts@$node_grpc_tools_node_protoc_ts_version grpc-tools@$node_grpc_tools_version protoc-gen-grpc-web@$node_protoc_gen_grpc_web_version

COPY --from=build /tmp/googleapis/google/ /opt/include/google
COPY --from=build /tmp/api-common-protos/google/ /opt/include/google

# Copy well known proto files
COPY --from=build /tmp/grpc/bazel-grpc/external/com_google_protobuf/src/google/protobuf/ /opt/include/google/protobuf/
# Copy protoc
COPY --from=build /tmp/grpc/bazel-bin/external/com_google_protobuf/ /usr/local/bin/
# Copy protoc default plugins
COPY --from=build /tmp/grpc/bazel-bin/src/compiler/ /usr/local/bin/
# Copy protoc java plugin
COPY --from=build /tmp/grpc-java/bazel-bin/compiler/ /usr/local/bin/
# Copy grpc_cli
COPY --from=build /tmp/grpc/bazel-bin/test/cpp/util/ /usr/local/bin/
# Copy buf
COPY --from=build /tmp/buf /usr/local/bin/

COPY --from=build /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=build /go/bin/* /usr/local/bin/
COPY --from=build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin

COPY --from=build /tmp/protoc-gen-scala /usr/local/bin/

COPY --from=build /go/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/v2@v${grpc_gateway_version}/protoc-gen-openapiv2/options /opt/include/protoc-gen-openapiv2/options/

COPY --from=build /go/src/github.com/envoyproxy/protoc-gen-validate/ /opt/include/
COPY --from=build /go/src/github.com/mwitkow/go-proto-validators/ /opt/include/github.com/mwitkow/go-proto-validators/

ADD all/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /defs
ENTRYPOINT [ "entrypoint.sh" ]

# protoc
FROM protoc-all AS protoc
ENTRYPOINT [ "protoc", "-I/opt/include" ]

# prototool
FROM protoc-all AS prototool
ENTRYPOINT [ "prototool" ]

# grpc-cli
FROM protoc-all as grpc-cli

ADD ./cli/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /run
ENTRYPOINT [ "/entrypoint.sh" ]

# gen-grpc-gateway
FROM protoc-all AS gen-grpc-gateway

COPY gwy/templates /templates
COPY gwy/generate_gateway.sh /usr/local/bin
RUN chmod +x /usr/local/bin/generate_gateway.sh

WORKDIR /defs
ENTRYPOINT [ "generate_gateway.sh" ]

# buf-cli
FROM protoc-all AS buf-cli
WORKDIR /workspace
ENTRYPOINT ["buf"]
