FROM registry.namely.tech/namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

# Install protoc go generator
###################################

RUN apt-get install -y golang

RUN mkdir -p /opt/go/
ENV GOPATH "/opt/go"

RUN go get -a github.com/golang/protobuf/protoc-gen-go
ENV PATH "$PATH:/opt/go/bin"

ADD script.sh /opt/namely/script.sh
CMD /opt/namely/script.sh
