FROM namely/protoc-all:1.10

COPY templates /templates
COPY generate_gateway.sh /usr/local/bin
RUN chmod +x /usr/local/bin/generate_gateway.sh

WORKDIR /defs
ENTRYPOINT ["generate_gateway.sh"]

