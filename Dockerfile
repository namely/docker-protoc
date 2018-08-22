ARG alpine=3.8
ARG go=1.10.3
ARG grpc

FROM golang:$go-alpine$alpine AS build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc

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
    libstdc++

WORKDIR /tmp
COPY all/install-protobuf.sh /tmp
RUN chmod +x /tmp/install-protobuf.sh
RUN /tmp/install-protobuf.sh $grpc
RUN git clone https://github.com/googleapis/googleapis

RUN curl -sSL https://github.com/uber/prototool/releases/download/v1.0.0-rc1/prototool-$(uname -s)-$(uname -m) \
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

FROM alpine:$alpine AS protoc-all

RUN set -ex && apk --update --no-cache add \
    bash \
    libstdc++

COPY --from=build /tmp/grpc/bins/opt/grpc_* /usr/local/bin/
COPY --from=build /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
COPY --from=build /tmp/grpc/libs/opt/ /usr/local/lib/
COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /tmp/googleapis/google/ /usr/local/include/google
COPY --from=build /usr/local/include/google/ /usr/local/include/google
COPY --from=build /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=build /go/bin/* /usr/local/bin/

COPY --from=build /go/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger/options/ /usr/local/include/protoc-gen-swagger/options/

ADD all/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /defs
ENTRYPOINT [ "entrypoint.sh" ]

# protoc
FROM protoc-all AS protoc
ENTRYPOINT [ "protoc", "-I/usr/local/include" ]

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

