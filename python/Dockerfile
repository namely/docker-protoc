FROM python:3.5
MAINTAINER Core Services <coreservices@namely.com>

ENV GRPC_RELEASE v1.1.0

# Install protoc python generator
###################################
RUN pip install grpcio-tools==$GRPC_RELEASE

WORKDIR /defs

COPY script.sh /opt/namely/script.sh
ENTRYPOINT ["/opt/namely/script.sh"]
