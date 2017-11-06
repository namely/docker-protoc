FROM alpine:3.4
MAINTAINER Core Services <coreservices@namely.com>

# Install Protoc
################
RUN set -ex \
	&& apk --update --no-cache add \
  bash \
	&& apk --no-cache add --virtual .pb-build \
  make \
	cmake \
  autoconf \
  automake \
  curl \
  tar \
  libtool \
	g++ \
  \
	&& mkdir -p /tmp/protobufs \
	&& cd /tmp/protobufs \
	&& curl -o protobufs.tar.gz -L https://github.com/google/protobuf/releases/download/v3.4.1/protobuf-cpp-3.4.1.tar.gz \
	&& mkdir -p protobuf \
	&& tar -zxvf protobufs.tar.gz -C /tmp/protobufs/protobuf --strip-components=1 \
	&& cd protobuf \
	&& ./autogen.sh \
	&& ./configure --prefix=/usr \
	&& make \
	&& make install \
  && cd \
	&& rm -rf /tmp/protobufs/ \
  && rm -rf /tmp/protobufs.tar.gz \
	&& apk --no-cache add libstdc++ \
	&& apk del .pb-build \
	&& rm -rf /var/cache/apk/* \
	&& mkdir /defs

RUN apk add --update git

# Clone in additional google API's protocol buffer definitions
# so every project can use definitions such as google.rpc.Status
WORKDIR /usr/include
RUN git clone https://github.com/googleapis/googleapis.git

# Change the working directory to where all definitions are expected to
# be mounted into
WORKDIR /defs