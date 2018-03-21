ARG alpine=3.6
ARG go=1.9.2

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

ENV GLIBC_COMPAT_VERSION 2.26-r0

RUN set -ex && \
	  apk --no-cache --update add nodejs nodejs-npm ca-certificates wget && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_COMPAT_VERSION}/glibc-${GLIBC_COMPAT_VERSION}.apk && \
    apk --no-cache add glibc-${GLIBC_COMPAT_VERSION}.apk

WORKDIR /tmp
COPY install-protobuf.sh /tmp
RUN chmod +x /tmp/install-protobuf.sh
RUN /tmp/install-protobuf.sh
RUN git clone https://github.com/googleapis/googleapis

FROM golang:$go-alpine$alpine

RUN set -ex && apk --update --no-cache add \
    bash \
    git \
    libstdc++ \
    nodejs \
    nodejs-npm

RUN go get -u google.golang.org/grpc
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
RUN go get -u github.com/golang/protobuf/protoc-gen-go

COPY --from=build /tmp/grpc/bins/opt/grpc_* /usr/local/bin/
COPY --from=build /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
COPY --from=build /tmp/grpc/libs/opt/ /usr/local/lib/
COPY --from=build /tmp/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin/
COPY --from=build /usr/bin/grpc_tools_node_protoc /usr/local/bin/
COPY --from=build /usr/bin/grpc_tools_node_protoc_plugin /usr/local/bin/
COPY --from=build /usr/lib/node_modules /usr/lib/
COPY --from=build /tmp/googleapis/google /usr/include/google
COPY --from=build /usr/local/include/google /usr/local/include/google

ADD entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /defs
ENTRYPOINT [ "entrypoint.sh" ]