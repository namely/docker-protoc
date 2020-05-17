ARG alpine=3.11
ARG go=1.14
ARG grpc
ARG grpc_java
ARG buf_version
ARG grpc_web

FROM golang:$go-alpine$alpine AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc
ARG grpc_java
ARG grpc_web
ARG buf_version

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
    unzip

WORKDIR /tmp
COPY all/install-protobuf.sh /tmp
RUN chmod +x /tmp/install-protobuf.sh
RUN /tmp/install-protobuf.sh ${grpc} ${grpc_java}

# Install Buf
COPY all/install-buf.sh /tmp
RUN chmod +x /tmp/install-buf.sh
RUN /tmp/install-buf.sh ${buf_version}

# Go get go-related bins
RUN go get -u google.golang.org/grpc

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
RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${grpc_web}/protoc-gen-grpc-web-${grpc_web}-linux-x86_64 \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

FROM alpine:$alpine AS grpckit

RUN set -ex && apk --update --no-cache add \
    bash \
    libstdc++ \
    libc6-compat \
    ca-certificates \
    nodejs \
    nodejs-npm

# Add TypeScript support

RUN npm config set unsafe-perm true
RUN npm i -g ts-protoc-gen@0.12.0

COPY --from=build /tmp/grpc/bins/opt/grpc_* /usr/local/bin/
COPY --from=build /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
COPY --from=build /tmp/grpc/libs/opt/ /usr/local/lib/
COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /usr/local/include/google/ /usr/local/include/google
COPY --from=build /go/bin/* /usr/local/bin/
COPY --from=build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin
COPY --from=build /usr/local/bin/buf /usr/local/bin/buf

COPY --from=build /tmp/protoc-gen-scala /usr/local/bin/

#COPY --from=build /go/src/github.com/envoyproxy/protoc-gen-validate/ /opt/include/github.com/envoyproxy/protoc-gen-validate/
#COPY --from=build /go/src/github.com/mwitkow/go-proto-validators/ /opt/include/github.com/mwitkow/go-proto-validators/

# protoc
FROM grpckit AS protoc
ENTRYPOINT [ "protoc", "-I/opt/include" ]

FROM grpckit as buf

ENTRYPOINT [ "buf" ]

FROM grpckit
