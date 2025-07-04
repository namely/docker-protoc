ARG debian_version
ARG go_version
ARG grpc_version
ARG grpc_gateway_version
ARG grpc_java_version
ARG scala_pb_version
ARG node_version
ARG node_grpc_tools_node_protoc_ts_version
ARG node_grpc_tools_version
ARG node_protoc_gen_grpc_web_version
ARG ts_proto_version
ARG go_bufbuild_pgv_version
ARG go_mwitkow_gpv_version
ARG go_protoc_gen_go_version
ARG go_protoc_gen_go_grpc_version
ARG mypy_version
ARG protobuf_js_version

FROM golang:$go_version-$debian_version AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc_version
ARG grpc_gateway_version
ARG grpc_java_version
ARG grpc_web_version
ARG scala_pb_version
ARG go_bufbuild_pgv_version
ARG go_mwitkow_gpv_version
ARG go_protoc_gen_go_version
ARG go_protoc_gen_go_grpc_version
ARG mypy_version
ARG protobuf_js_version


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
    clang \
    python3-pip

WORKDIR /tmp
RUN git clone --depth 1 --shallow-submodules -b v$grpc_version.x --recursive https://github.com/grpc/grpc && \
    git clone --depth 1 --shallow-submodules -b v$grpc_java_version.x --recursive https://github.com/grpc/grpc-java && \
    git clone --depth 1 --shallow-submodules -b $protobuf_js_version --recursive https://github.com/protocolbuffers/protobuf-javascript && \
    git clone --depth 1 https://github.com/googleapis/googleapis && \
    git clone --depth 1 https://github.com/googleapis/api-common-protos

ARG bazel=/tmp/grpc/tools/bazel

WORKDIR /tmp/grpc
RUN $bazel build //external:protocol_compiler && \
    $bazel build //src/compiler:all && \
    $bazel build //test/cpp/util:grpc_cli

WORKDIR /tmp/grpc-java
RUN $bazel build //compiler:grpc_java_plugin

WORKDIR /tmp/protobuf-javascript
RUN $bazel build //generator:protoc-gen-js

WORKDIR /tmp
# Install protoc required by bufbuild/protoc-gen-validate package
RUN cp -a /tmp/grpc/bazel-bin/external/com_google_protobuf/. /usr/local/bin/
# Copy well known proto files required by bufbuild/protoc-gen-validate package
RUN mkdir -p /usr/local/include/google/protobuf && \
    cp -a /tmp/grpc/bazel-grpc/external/com_google_protobuf/src/google/protobuf/. /usr/local/include/google/protobuf/

# go install go-related bins
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@${go_protoc_gen_go_grpc_version}

# install protoc-gen-grpc-gateway and protoc-gen-openapiv2
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@${grpc_gateway_version}
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@${grpc_gateway_version}

RUN go install github.com/gogo/protobuf/protoc-gen-gogo@latest
RUN go install github.com/gogo/protobuf/protoc-gen-gogofast@latest

RUN go install github.com/ckaznocha/protoc-gen-lint@latest

RUN go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@latest

RUN go install github.com/micro/micro/v3/cmd/protoc-gen-micro@latest

RUN go install github.com/bufbuild/protoc-gen-validate@v${go_bufbuild_pgv_version}

# Add Ruby Sorbet types support (rbi)
RUN go install github.com/coinbase/protoc-gen-rbi@latest

RUN go install github.com/gomatic/renderizer/v2/cmd/renderizer@latest

# Origin protoc-gen-go should be installed last, for not been overwritten by any other binaries(see #210)
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@${go_protoc_gen_go_version}

RUN go install github.com/mwitkow/go-proto-validators/protoc-gen-govalidators@v${go_mwitkow_gpv_version}

# Add scala support
RUN curl -fLO "https://github.com/scalapb/ScalaPB/releases/download/v${scala_pb_version}/protoc-gen-scala-${scala_pb_version}-linux-x86_64.zip" \
    && unzip protoc-gen-scala-${scala_pb_version}-linux-x86_64.zip \
    && chmod +x /tmp/protoc-gen-scala

# Add grpc-web support
RUN curl -fsSL "https://github.com/grpc/grpc-web/releases/download/${grpc_web_version}/protoc-gen-grpc-web-${grpc_web_version}-linux-x86_64" \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

# Add mypy support
RUN pip3 install -t /opt/mypy-protobuf mypy-protobuf==${mypy_version}

FROM debian:$debian_version-slim AS protoc-all

ARG grpc_version
ARG grpc_gateway_version

ARG node_version
ARG node_grpc_tools_node_protoc_ts_version
ARG node_grpc_tools_version
ARG node_protoc_gen_grpc_web_version
ARG ts_proto_version

ARG go_bufbuild_pgv_version
ARG go_mwitkow_gpv_version

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
RUN curl -fsSL "https://deb.nodesource.com/setup_${node_version}.x" | bash -
RUN apt-get install -y nodejs

# Add Node TypeScript support
RUN npm i -g grpc_tools_node_protoc_ts@$node_grpc_tools_node_protoc_ts_version grpc-tools@$node_grpc_tools_version protoc-gen-grpc-web@$node_protoc_gen_grpc_web_version

# Add TypeScript support
RUN npm i -g ts-proto@$ts_proto_version

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
# Copy protoc js plugin
COPY --from=build /tmp/protobuf-javascript/bazel-bin/generator/protoc-gen-js /usr/local/bin/
# Copy grpc_cli
COPY --from=build /tmp/grpc/bazel-bin/test/cpp/util/ /usr/local/bin/

COPY --from=build /go/bin/* /usr/local/bin/
COPY --from=build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin

COPY --from=build /tmp/protoc-gen-scala /usr/local/bin/

COPY --from=build /go/pkg/mod/github.com/grpc-ecosystem/grpc-gateway/v2@${grpc_gateway_version}/protoc-gen-openapiv2/options /opt/include/protoc-gen-openapiv2/options/

COPY --from=build /go/pkg/mod/github.com/bufbuild/protoc-gen-validate@v${go_bufbuild_pgv_version}/ /opt/include/

COPY --from=build /go/pkg/mod/github.com/mwitkow/go-proto-validators@v${go_mwitkow_gpv_version}/ /opt/include/github.com/mwitkow/go-proto-validators/

# Copy mypy
COPY --from=build /opt/mypy-protobuf/ /opt/mypy-protobuf/
RUN mv /opt/mypy-protobuf/bin/* /usr/local/bin/
ENV PYTHONPATH="${PYTHONPATH:+$PYTHONPATH:}/opt/mypy-protobuf/"

ADD all/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /defs
ENTRYPOINT [ "entrypoint.sh" ]

# protoc
FROM protoc-all AS protoc
ENTRYPOINT [ "protoc", "-I/opt/include" ]

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
