FROM registry.namely.tech/namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

# Install protoc ruby generator
###################################

RUN apk add ruby ruby-dev
RUN gem install --prerelease --no-ri --no-rdoc google-protobuf

RUN mkdir -p /opt/namely
ADD script.sh /opt/namely/script.sh
CMD /opt/namely/script.sh
