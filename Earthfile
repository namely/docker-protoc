ARG debian=buster
ARG go_version=1.14
ARG grpc_version=1.33
ARG grpc_java_version=1.33
FROM golang:$go_version-$debian

build-base:
  # TIL docker arg variables need to be redefined in each build stage
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

build-grpc-base:
  FROM +build-base
  ARG GRPC_VERSION=1.33
  WORKDIR /tmp
  RUN git clone --depth 1 --shallow-submodules -b v${GRPC_VERSION}.x --recursive https://github.com/grpc/grpc
  WORKDIR /tmp/grpc

build-protoc:
  FROM +build-grpc-base
  ARG bazel=/tmp/grpc/tools/bazel
  RUN $bazel build //external:protocol_compiler
  SAVE ARTIFACT /tmp/grpc /grpc

build-compilers:
  FROM +build-grpc-base
  ARG bazel=/tmp/grpc/tools/bazel
  RUN $bazel build //src/compiler:all
  SAVE ARTIFACT /tmp/grpc /grpc

build-grpc_cli:
  FROM +build-grpc-base
  ARG bazel=/tmp/grpc/tools/bazel
  RUN $bazel build //test/cpp/util:grpc_cli
  SAVE ARTIFACT /tmp/grpc /grpc

build-grpc-java:
  ARG GRPC_JAVA_VERSION=1.33
  ARG GRPC_WEB_VERSION=1.33
  ARG bazel=/tmp/grpc/tools/bazel
  WORKDIR /tmp
  RUN git clone --depth 1 --shallow-submodules -b v${GRPC_JAVA_VERSION}.x --recursive https://github.com/grpc/grpc-java.git
  WORKDIR /tmp/grpc-java
  RUN $bazel build //compiler:grpc_java_plugin
  SAVE ARTIFACT /tmp/grpc-java /grpc-java

build-grpc-go:
  ARG GRPC_JAVA_VERSION=1.33
  ARG bazel=/tmp/grpc/tools/bazel
  WORKDIR /tmp
  RUN git clone --depth 1 --shallow-submodules -b v${GRPC_JAVA_VERSION}.x --recursive https://github.com/grpc/grpc-java.git
  WORKDIR /tmp/grpc-java
  RUN $bazel build //compiler:grpc_java_plugin
  SAVE ARTIFACT /tmp/grpc-java /grpc-java

      git clone --depth 1 --shallow-submodules -b v${GRPC_VERSION}.x --recursive https://github.com/grpc/grpc-go.git && \
      git clone --depth 1 https://github.com/googleapis/googleapis && \
      git clone --depth 1 https://github.com/googleapis/api-common-protos

  

  WORKDIR /tmp/grpc-java
  RUN $bazel build //compiler:grpc_java_plugin

  SAVE ARTIFACT /tmp /tmp

  # WORKDIR /tmp
  # # Install protoc required by envoyproxy/protoc-gen-validate package
  # RUN cp -a /tmp/grpc/bazel-bin/external/com_google_protobuf/. /usr/local/bin/
  # # Copy well known proto files required by envoyproxy/protoc-gen-validate package
  # RUN mkdir -p /usr/local/include/google/protobuf && \
  #     cp -a /tmp/grpc/bazel-grpc/external/com_google_protobuf/src/google/protobuf/. /usr/local/include/google/protobuf/

prototool:
  FROM +build-base
  WORKDIR /tmp
  RUN curl -sSL https://github.com/uber/prototool/releases/download/v1.3.0/prototool-$(uname -s)-$(uname -m) \
      -o /usr/local/bin/prototool && \
      chmod +x /usr/local/bin/prototool

  # Workaround for the transition to protoc-gen-go-grpc
  # https://grpc.io/docs/languages/go/quickstart/#regenerate-grpc-code
  WORKDIR grpc-go/cmd/protoc-gen-go-grpc
  RUN go install .

  # Go get go-related bins
  WORKDIR /tmp
  RUN go get -u google.golang.org/grpc

  RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
  RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2

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
  RUN curl -LO https://github.com/scalapb/ScalaPB/releases/download/v0.9.6/protoc-gen-scala-0.9.6-linux-x86_64.zip \ 
      && unzip protoc-gen-scala-0.9.6-linux-x86_64.zip \
      && chmod +x /tmp/protoc-gen-scala

  # Add grpc-web support
  RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 \
      -o /tmp/grpc_web_plugin && \
      chmod +x /tmp/grpc_web_plugin
  
  SAVE ARTIFACT /

protoc-all:
  ARG debian=buster
  FROM debian:$debian-slim
  ARG GRPC_VERSION=1.33

  RUN mkdir -p /usr/share/man/man1
  RUN set -ex && apt-get update && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      nodejs \
      npm \
      zlib1g \
      libssl1.1 \
      openjdk-11-jre \
      dos2unix \
      gawk

  RUN npm config set unsafe-perm true
  RUN npm i -g ts-protoc-gen@0.12.0

  # Copy well known proto files
  COPY --dir +build-base/tmp/grpc/bazel-grpc/external/com_google_protobuf/src/google/protobuf /opt/include/google/.
  # Copy protoc
  COPY +build-base/tmp/grpc/bazel-bin/external/com_google_protobuf/ /usr/local/bin/
  # Copy protoc default plugins
  COPY +build-base/tmp/grpc/bazel-bin/src/compiler/ /usr/local/bin/
  # Copy protoc java plugin
  COPY +build-base/tmp/grpc-java/bazel-bin/compiler/ /usr/local/bin/
  # Copy grpc_cli
  COPY +build-base/tmp/grpc/bazel-bin/test/cpp/util/ /usr/local/bin/

  COPY +build-base/usr/local/bin/prototool /usr/local/bin/prototool
  COPY +build-base/go/bin /usr/local/bin/
  COPY +build-base/tmp/grpc_web_plugin /usr/local/bin/.

  COPY +build-base/tmp/protoc-gen-scala /usr/local/bin/.

  COPY --dir +build-base/go/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2/options/ /opt/include/protoc-gen-openapiv2/.

  COPY --dir +build-base/go/src/github.com/envoyproxy/protoc-gen-validate/validate /opt/include/
  COPY +build-base/go/src/github.com/mwitkow/go-proto-validators /opt/include/github.com/mwitkow/go-proto-validators/.
  
  COPY all/entrypoint.sh /usr/local/bin/.
  RUN chmod +x /usr/local/bin/entrypoint.sh
  WORKDIR /defs
  ENTRYPOINT [ "entrypoint.sh" ]
  SAVE IMAGE namely/protoc-all:${GRPC_VERSION}_1