# Template for grpc-gateway 

ARG alpine_version=3.8
FROM golang:1.10-alpine$alpine_version AS build

RUN apk add --update --no-cache git
WORKDIR /app
ENV GOPATH=/app

# Copy all of the staged files (protos plus go source)
COPY . /app/

# Download the go dependencies.
RUN go get ./...

WORKDIR /app

# Build the gateway
RUN go build -o grpc_gateway src/pkg/main/main.go

FROM alpine:$alpine_version
WORKDIR /app
COPY --from=build /app/grpc_gateway /app/
COPY --from=build /app/config.yaml /app/
COPY --from=build /app/src/${GATEWAY_IMPORT_DIR}/${SWAGGER_FILE_NAME} /app/

EXPOSE 80
ENTRYPOINT ["/app/grpc_gateway"]
