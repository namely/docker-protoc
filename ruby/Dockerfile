FROM registry.namely.tech/namely/protoc
MAINTAINER Core Services <coreservices@namely.com>

# Install protoc ruby generator
###################################

RUN apt-get install -y ruby ruby-dev zlib1g-dev
RUN gem install --no-ri --no-rdoc grpc

RUN mkdir -p /opt/namely
ADD script.sh /opt/namely/script.sh
CMD /opt/namely/script.sh
