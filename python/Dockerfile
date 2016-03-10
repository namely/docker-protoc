FROM namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

ENV GRPC_RELEASE release-0_13

# Install protoc python generator
###################################

RUN set -ex \
	&& apk --no-cache --update add --virtual .python-builder \
  git \
  gcc \
  g++ \
  openssl \
  make \
	cmake \
  autoconf \
  automake \
  libtool \
  \
  && mkdir -p /usr/local/grpc \
  && git clone https://github.com/grpc/grpc.git /usr/local/grpc \
  \
  && cd /usr/local/grpc \
  && git checkout $GRPC_RELEASE \
  && git submodule update --init \
  \
  && cd /usr/local/grpc \
  && make grpc_python_plugin \
  \
  && mkdir -p /opt/namely \
  && cp /usr/local/grpc/bins/opt/grpc_python_plugin /opt/namely \
  && apk del .python-builder \
	&& rm -rf /var/cache/apk/* \
  && rm -rf /usr/local/grpc \
  && rm -rf /usr/local/include

COPY script.sh /opt/namely/script.sh
ENTRYPOINT ["/opt/namely/script.sh"]
