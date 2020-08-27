ARG alpine_version=3.12
ARG go_version=1.14
ARG grpc_version
ARG grpc_java_version
ARG proto_version

FROM golang:$go_version-alpine$alpine_version AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc_version
ARG grpc_java_version
ARG grpc_web_version
ARG proto_version

RUN set -ex && apk --update --no-cache add \
    bash \
    make \
    cmake \
    autoconf \
    automake \
    curl \
    tar \
    libtool \
    g++ \
    git \
    openjdk8-jre \
    libstdc++ \
    ca-certificates \
    nss \
    linux-headers \
    unzip \
    protoc~=${proto_version} \
    protobuf-dev~=${proto_version}

RUN set -ex && apk --update --no-cache add \
    grpc~=${grpc_version} \
    grpc-dev~=${grpc_version} \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

WORKDIR /tmp

RUN git clone -b v${grpc_java_version}.x --recursive https://github.com/grpc/grpc-java.git
WORKDIR /tmp/grpc-java/compiler
RUN ../gradlew -PskipAndroid=true java_pluginExecutable

WORKDIR /tmp
RUN git clone https://github.com/googleapis/googleapis

RUN curl -sSL https://github.com/uber/prototool/releases/download/v1.3.0/prototool-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/prototool && \
    chmod +x /usr/local/bin/prototool

# Go get go-related bins
WORKDIR /tmp
RUN go get -u google.golang.org/grpc

RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
RUN go get -u github.com/golang/protobuf/protoc-gen-go

RUN go get -u github.com/gogo/protobuf/protoc-gen-gogo
RUN go get -u github.com/gogo/protobuf/protoc-gen-gogofast

RUN go get -u github.com/ckaznocha/protoc-gen-lint
RUN go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

RUN go get -u github.com/micro/protobuf/protoc-gen-go

RUN go get -d github.com/envoyproxy/protoc-gen-validate
RUN make -C /go/src/github.com/envoyproxy/protoc-gen-validate/ build

RUN go get -u github.com/mwitkow/go-proto-validators/protoc-gen-govalidators

# Add Ruby Sorbet types support (rbi)
RUN go get -u github.com/coinbase/protoc-gen-rbi

RUN go get github.com/gomatic/renderizer/cmd/renderizer

# Add scala support
RUN curl -LO https://github.com/scalapb/ScalaPB/releases/download/v0.9.6/protoc-gen-scala-0.9.6-linux-x86_64.zip \ 
    && unzip protoc-gen-scala-0.9.6-linux-x86_64.zip \
    && chmod +x /tmp/protoc-gen-scala

# Add grpc-web support
RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${grpc_web_version}/protoc-gen-grpc-web-${grpc_web_version}-linux-x86_64 \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

FROM alpine:$alpine_version AS protoc-all

ARG grpc_version
ARG proto_version

RUN set -ex && apk --update --no-cache add \
    bash \
    libstdc++ \
    libc6-compat \
    ca-certificates \
    nodejs \
    nodejs-npm \
    protoc~=${proto_version}

RUN set -ex && apk --update --no-cache add \
    grpc~=${grpc_version} \
    grpc-cli~=${grpc_version} \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

# Add TypeScript support

RUN npm config set unsafe-perm true
RUN npm i -g ts-protoc-gen@0.12.0

COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /tmp/googleapis/google/ /opt/include/google
COPY --from=build /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=build /go/bin/* /usr/local/bin/
COPY --from=build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin

COPY --from=build /tmp/protoc-gen-scala /usr/local/bin/

COPY --from=build /go/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger/options/ /opt/include/protoc-gen-swagger/options/

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
