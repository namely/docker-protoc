#!/bin/bash

set -e

HTTP_PORT=80

printUsage() {
  echo "Generates a docker image of a grpc-gateway server for a given service proto."  
  echo
  echo "The container will listen on port ${HTTP_PORT} for HTTP traffic, and proxy requests"
  echo "to the gRPC service. In addition, it will serve a Swagger definition of its API at"
  echo "/swagger.json"
  echo
  echo "When using this container, pass in -backend as an argument, pointing to the gRPC"
  echo "service backend that is being proxied."
  echo
  echo "Options:"
  echo "-h, --help                 Show this message."
  echo "-f, --file FILE            The proto file to generate a gateway for."
  echo "-s, --service SERVICE      The name of the gRPC service."
  echo "-c, --container CONTAINER  The name of the docker container to generate."
}

#### PARSE ARGUMENTS ####
# Path to the proto file.
FILE=""
# Name of the service
SERVICE=""
# Name of the container
CONTAINER=""

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      printUsage
      exit 0
      ;;
    -f|--file)
      shift
      if test $# -gt 0; then
        FILE=$1
      else
        printUsage
        exit 1
      fi
      shift
      ;;
    -s|--service)
      shift
      if test $# -gt 0; then
        SERVICE=$1
      else
        printUsage
        exit 1
      fi
      shift
      ;;
    -c|--container)
      shift
      if test $# -gt 0; then
        CONTAINER=$1
      else
        printUsage
        exit 1
      fi
      shift
      ;;
    *)
      printUsage
      exit 1
      ;;
  esac
done

#### VALIDATE INPUT ####
if [[ -z $SERVICE ]]; then
  echo "Error: You must specify the proto service name"
  printUsage
  exit 1
fi

if [[ -z $CONTAINER ]]; then
  echo "Error: You must specify the Docker container name"
  printUsage
  exit 1
fi

#### BUILD GATEWAY PROJECT ####
TMPDIR=`mktemp -d /tmp/grpc-gateway.XXXXXXXXXX`
echo "Creating template project in $TMPDIR."

echo "Copying protos into $TMPDIR."
PROTO_DIR=$(dirname $FILE)
PROTO_FILE=$(basename $FILE)
SWAGGER_FILE_NAME=`basename $PROTO_FILE .proto`.swagger.json

# Copy everything in the proto file's directory,
# plus any dependencies.
mkdir -p $TMPDIR/src/proto/
cp -r $PROTO_DIR/ $TMPDIR/src/proto/

echo "Generating entry-point code."
mkdir -p $TMPDIR/src/pkg/main/

cat << ENTRYPOINT >> $TMPDIR/src/pkg/main/main.go
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
  "os/signal"
  "strings"
  "time"

  "github.com/grpc-ecosystem/grpc-gateway/runtime"
  "github.com/spf13/viper"
  "golang.org/x/net/context"
  "google.golang.org/grpc"

  gw "gen/pb-go"
)

type proxyConfig struct {
  backend string
  swagger string
}

func SetupMux(ctx context.Context, cfg proxyConfig) *http.ServeMux {
  mux := http.NewServeMux()

  mux.HandleFunc("/swagger.json", func(w http.ResponseWriter, r *http.Request) {
    http.ServeFile(w, r, cfg.swagger)
  })

  opts := []grpc.DialOption{grpc.WithInsecure()}
  gwmux := runtime.NewServeMux()
  err := gw.Register${SERVICE}HandlerFromEndpoint(ctx, gwmux, cfg.backend, opts)
  if err != nil {
    log.Fatalf("Could not register gateway: %v", err)
  }
  mux.Handle("/", gwmux)

  return mux
}

// SetupViper returns a viper configuration object
func SetupViper() *viper.Viper {
  viper.SetConfigName("config")
  viper.AddConfigPath(".")
  viper.SetEnvPrefix("${SERVICE}")
  viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
  viper.AutomaticEnv()

  err := viper.ReadInConfig()
  if err != nil {
    log.Fatalf("Could not read config: %v", err)
  }

  return viper.GetViper()
}

// SignalRunner runs a runner function until an interrupt signal is received, at which point it
// will call stopper.
func SignalRunner(runner, stopper func()) {
  signals := make(chan os.Signal, 1)
  signal.Notify(signals, os.Interrupt, os.Kill)

  go func() {
    runner()
  }()

  fmt.Println("hit Ctrl-C to shutdown")
  select {
  case <-signals:
    stopper()
  }
}

func main() {

  cfg := SetupViper()
  ctx := context.Background()
  ctx, cancel := context.WithCancel(ctx)
  defer cancel()

  mux := SetupMux(ctx, proxyConfig{
    backend: cfg.GetString("backend"),
    swagger: cfg.GetString("swagger.file"),
  })

  addr := fmt.Sprintf(":%v", cfg.GetInt("proxy.port"))
  server := &http.Server{Addr: addr, Handler: mux}

  SignalRunner(
    func() {
      fmt.Printf("launching http server on %v\n", server.Addr)
      if err := server.ListenAndServe(); err != nil {
        log.Fatalf("Could not start http server: %v", err)
      }
    },
    func() {
      shutdown, _ := context.WithTimeout(ctx, 10*time.Second)
      server.Shutdown(shutdown)
    })
}
ENTRYPOINT

# Generate a service config file.
cat << VIPER >> $TMPDIR/config.yaml
backend:
proxy:
  port: ${HTTP_PORT}
swagger:
  file: "${SWAGGER_FILE_NAME}"
VIPER

# Generate the docker file.
echo "Generating Dockerfile."
cat << DOCKERFILE >> $TMPDIR/Dockerfile
FROM namely/protoc-all AS build
WORKDIR /app
ENV GOPATH=/app

# Copy all of the staged files (protos plus go source)
COPY . /app/

# Build the proto files.
WORKDIR /app/src
RUN entrypoint.sh -d proto -l go --with-gateway

# Download the go dependencies.
RUN go get ./...

WORKDIR /app
# Build the gateway
RUN go build -o grpc_gateway src/pkg/main/main.go

FROM alpine:3.6
WORKDIR /app
COPY --from=build /app/grpc_gateway /app/
COPY --from=build /app/config.yaml /app/
COPY --from=build /app/src/gen/pb-go/$SWAGGER_FILE_NAME /app/

EXPOSE ${HTTP_PORT}
ENTRYPOINT /app/grpc_gateway
DOCKERFILE

# Build the docker file
echo "Building docker container $CONTAINER."
docker build -t $CONTAINER -f $TMPDIR/Dockerfile $TMPDIR

echo "Generation done."
rm -rf $TMPDIR
