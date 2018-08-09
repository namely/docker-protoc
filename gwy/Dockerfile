ARG protoc_version=1.15
FROM namely/protoc-all:$protoc_version

COPY templates /templates
COPY generate_gateway.sh /usr/local/bin
RUN chmod +x /usr/local/bin/generate_gateway.sh

WORKDIR /defs
ENTRYPOINT ["generate_gateway.sh"]
