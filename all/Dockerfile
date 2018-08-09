ARG alpine=3.8
ARG go=1.10.3

FROM golang:$go-alpine$alpine AS build

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
    openjdk8-jre

WORKDIR /tmp
COPY install-protobuf.sh /tmp
RUN chmod +x /tmp/install-protobuf.sh
RUN /tmp/install-protobuf.sh
RUN git clone https://github.com/googleapis/googleapis

FROM golang:$go-alpine$alpine

RUN set -ex && apk --update --no-cache add \
    bash \
    git \
    libstdc++

RUN go get -u google.golang.org/grpc
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
RUN go get -u github.com/golang/protobuf/protoc-gen-go

RUN go get -u github.com/gogo/protobuf/protoc-gen-gogo
RUN go get -u github.com/gogo/protobuf/protoc-gen-gogofast
RUN go get -u github.com/ckaznocha/protoc-gen-lint
RUN go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

COPY --from=build /tmp/grpc/bins/opt/grpc_* /usr/local/bin/
COPY --from=build /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
COPY --from=build /tmp/grpc/libs/opt/ /usr/local/lib/
COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /tmp/googleapis/google /usr/include/google
COPY --from=build /usr/local/include/google /usr/local/include/google

RUN mkdir -p /usr/local/include/protoc-gen-swagger/options/
RUN cp -R /go/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger/options/ /usr/local/include/protoc-gen-swagger/

ADD entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /defs
ENTRYPOINT [ "entrypoint.sh" ]
