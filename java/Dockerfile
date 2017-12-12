FROM namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

ENV GRPC_RELEASE v1.8.x 

# Install protoc java generator
###################################

# 1. Install Gradle
# 2. Install compile protoc plugin

ENV GRADLE_HOME /opt/gradle
ENV PATH $PATH:$GRADLE_HOME/bin

ENV CXXFLAGS="-I usr/local/include"
ENV LDFLAGS="-L/usr/local/lib"

RUN set -ex \
	&& apk --no-cache --update add --virtual .java-builder \
  bash \
  alpine-sdk \
  musl-dev \
  g++ \
  curl \
  git \
  openjdk8-jre\
  \
  && mkdir -p /usr/local/grpc \
  && git clone https://github.com/grpc/grpc-java.git /usr/local/grpc \
  \
  && cd /usr/local/grpc \
  && git checkout $GRPC_RELEASE \
  && git submodule update --init \
  \
  && sh -c 'echo /usr/local/lib >> /etc/ld.so.conf' \
  \
  && cd /usr/local/grpc/compiler \
  && ../gradlew java_pluginExecutable \
  \
  && mkdir -p /opt/namely \
  && cp /usr/local/grpc/compiler/build/exe/java_plugin/protoc-gen-grpc-java /opt/namely \
  && apk del .java-builder \
	&& rm -rf /var/cache/apk/* \
  && rm -rf /usr/local/grpc \
  && rm -rf /usr/include \
  && rm -rf /root/.gradle \
  && rm -rf /usr/lib/engines \
  && rm -rf /usr/lib/jvm \
  && rm -rf /usr/local/include

COPY script.sh /opt/namely/script.sh
ENTRYPOINT ["/opt/namely/script.sh"]
