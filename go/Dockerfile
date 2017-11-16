FROM namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

RUN apk add --update go
RUN mkdir -p /go
ENV GOPATH /go
RUN go get -u github.com/golang/protobuf/protoc-gen-go

ENV PATH $PATH:/go/bin

COPY script.sh /opt/namely/script.sh
ENTRYPOINT ["/opt/namely/script.sh"]
