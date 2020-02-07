ARG alpine=3.9
ARG go=1.12
ARG grpc
ARG grpc_java

FROM golang:$go-alpine$alpine AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc
ARG grpc_java
ARG grpc_web=1.0.7
ARG nanopb=0.4.1

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
    linux-headers

WORKDIR /tmp
COPY all/install-protobuf.sh /tmp
RUN chmod +x /tmp/install-protobuf.sh
RUN /tmp/install-protobuf.sh ${grpc} ${grpc_java}
RUN git clone https://github.com/googleapis/googleapis

RUN curl -sSL https://github.com/uber/prototool/releases/download/v1.3.0/prototool-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/prototool && \
    chmod +x /usr/local/bin/prototool

# Go get go-related bins
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

# Add grpc-web support

RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${grpc_web}/protoc-gen-grpc-web-${grpc_web}-linux-x86_64 \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

RUN curl -sSL https://jpa.kapsi.fi/nanopb/download/nanopb-${nanopb}-linux-x86.tar.gz \
    -o /tmp/nanopb.tar.gz && \
    mkdir -p /tmp/nanopb && \
    tar -xzf /tmp/nanopb.tar.gz --strip 1 -C /tmp/nanopb

FROM alpine:3.9 AS protoc-all

RUN set -ex && apk --update --no-cache add \
    bash \
    libstdc++ \
    libc6-compat \
    ca-certificates \
    nodejs \
    nodejs-npm \
    python \
    py2-pip && \
    pip install protobuf

# Add TypeScript support

RUN npm i -g ts-protoc-gen@0.11.0

COPY --from=build /tmp/grpc/bins/opt/grpc_* /usr/local/bin/
COPY --from=build /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
COPY --from=build /tmp/grpc/libs/opt/ /usr/local/lib/
COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /tmp/googleapis/google/ /opt/include/google
COPY --from=build /usr/local/include/google/ /opt/include/google
COPY --from=build /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=build /go/bin/* /usr/local/bin/
COPY --from=build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin

COPY --from=build /go/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger/options/ /opt/include/protoc-gen-swagger/options/

COPY --from=build /go/src/github.com/envoyproxy/protoc-gen-validate/ /opt/include/
COPY --from=build /go/src/github.com/mwitkow/go-proto-validators/ /opt/include/github.com/mwitkow/go-proto-validators/
COPY --from=build /tmp/nanopb/generator/ /usr/local/lib/protoc-gen-nanopb/
COPY --from=build /tmp/nanopb/generator/nanopb/ /opt/include/nanopb/options/
COPY --from=build /tmp/nanopb/generator/proto/nanopb.proto /opt/include/nanopb/nanopb.proto

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
