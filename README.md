# gRPC/Protocol Buffer Compiler Containers

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e20c6e95969a4926abd1dc778e8c8e7e)](https://app.codacy.com/gh/namely/docker-protoc/dashboard)
[![GitHub Workflow Status (branch)](https://github.com/namely/docker-protoc/actions/workflows/master.yml/badge.svg)](https://github.com/namely/docker-protoc/actions?query=workflow%3AMaster)
[![Docker Pulls](https://img.shields.io/docker/pulls/namely/protoc-all?style=flat-square)](https://hub.docker.com/repository/docker/namely/protoc-all)

This repository contains support for various Docker images that wrap `protoc`,
`prototool`, `grpc_cli` commands with [gRPC](https://github.com/grpc/grpc) support
in a variety of languages removing the need to install and manage these commands locally.
It relies on setting a simple volume to the docker container,
usually mapping the current directory to `/defs`, and specifying the file and
language you want to generate.

## Features

*   Docker images for:
    *   `protoc` with `namely/protoc` (automatically includes `/usr/local/include`)
    *   [Uber's Prototool](https://github.com/uber/prototool) with `namely/prototool`
    *   A custom generation script to facilitate common use-cases with `namely/protoc-all` (see below)
    *   `grpc_cli` with `namely/grpc-cli`
    *   [gRPC Gateway](https://github.com/grpc-ecosystem/grpc-gateway) using a custom go-based server with `namely/gen-grpc-gateway`
*   [Google APIs](https://github.com/googleapis/googleapis) included in `/opt/include/google`
*   [Protobuf library artifacts](https://github.com/google/protobuf/tree/master/src/google/protobuf) included in `/opt/include/google/protobuf`.  NOTE: `protoc` would only need part of the path i.e. `-I /opt/include` if you import WKTs like so:

```proto
import "google/protobuf/empty.proto";
...
```

*   Support for all C-based gRPC libraries with Go and Java native libraries

If you're having trouble, see [Docker troubleshooting](#docker-troubleshooting) below.

> Note - throughout this document, commands for bash are prefixed with `$` and commands
> for PowerShell on Windows are prefixed with `PS>`. It is not required to use "Windows
> Subsystem for Linux" (WSL) except for development work on docker-protoc itself

## Tag Conventions

For `protoc`, `grpc_cli` and `prototool` a pattern of `<GRPC_VERSION>_<CONTAINER_VERSION>` is used for all images (or `<GRPC_VERSION>_<CONTAINER_VERSION>-rc.<PRERELEASE_NUMBER>`) for pre-releases).
Example is `namely/protoc-all:1.15_0` for gRPC version `1.15` (or `namely/protoc-all:1.15_0-rc.1` for a pre-release). The `latest` tag will always point to the most recent version.

## Usage

Pull the container:

```sh
$ docker pull namely/protoc-all
```

After that, change working directory to the one that contains your `.proto` definition
files.

So if you have a directory: `~/my_project/protobufs/` that has: `myproto.proto`, you'd want to run this:

```sh
$ cd ~/my_project/protobufs
$ docker run -v $PWD:/defs namely/protoc-all -f myproto.proto -l ruby #or go, csharp, etc
```

```powershell
PS> cd ~/my_project/protobufs
PS> docker run -v ${pwd}:/defs namely/protoc-all -f myproto.proto -l ruby #or go, csharp, etc
```

The container automatically puts the compiled files into a `gen` directory with
language-specific sub-directories. So for Golang, the files go into a directory
`./gen/pb-go`; For ruby the directory is `./gen/pb-ruby`.

## Options

You can use the `-o` flag to specify an output directory. This will
automatically be created. For example, add `-o my-gen` to add all fileoutput to
the `my-gen` directory. In this case, `pb-*` subdirectories will not be created.

You can use the `-d` flag to generate all proto files in a directory. You cannot
use this with the `-f` option.

You can also use `-i` to add extra include directories. This can be helpful to
*lift* protofiles up a directory when generating. As an example, say you have a
file `protorepo/catalog/catalog.proto`. This will by default output to
`gen/pb-go/protorepo/catalog/` because `protorepo` is part of the file path
input. To remove the `protorepo` you need to add an include and change the
import:

```sh
$ docker run ... namely/protoc-all -i protorepo -f catalog/catalog.proto -l go
# instead of
$ docker run ... namely/protoc-all -f protorepo/catalog/catalog.proto -l go
# which will generate files in a `protorepo` directory.
```

### Ruby-specific options

`--with-rbi` to generate Ruby Sorbet type definition .rbi files

### node/web-specific options

`--js-out <string>` to modify the `js_out=` options for node and web code generation

`--grpc-web-out <string>` to modify the `grpc-web_out=` options for web code generation

`--grpc-out <string>` to modify the `grpc_out=` options for node and web code generation.  See https://www.npmjs.com/package/grpc-tools for more details.

## gRPC Gateway

This repo also provides a docker image `namely/gen-grpc-gateway` to generate a
[grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway) server.
By annotating your proto (see the grpc-gateway documentation), you can generate a
server that acts as an HTTP server, and a gRPC client to your gRPC service.

Generate a gRPC Gateway docker project with

```sh
docker run -v `pwd`:/defs namely/gen-grpc-gateway -f path/to/your/proto.proto -s Service
```

where `Service` is the name of your gRPC service defined in the proto. This will create a
folder with a simple go server.
By default, this goes in the `gen/grpc-gateway` folder. You can then build the contents of this
folder into an actual runnable grpc-gateway server.

Build your gRPC Gateway server with

```sh
docker build -t my-grpc-gateway gen/grpc-gateway/
```

*NOTE*: If your service does not contain any `(google.api.http)` annotations, this build will
fail with an error `...HandlerFromEndpoint is undefined`. You need to have at least one rpc
method annotated to build a gRPC Gateway, or use `--generate-unbound-methods` option to expose
all the methods in your proto file

Run this image with

```sh
docker run my-grpc-gateway --backend=grpc-service:50051
```

where `--backend` refers to your actual gRPC server's address. The gRPC gateway
listens on port `80` for HTTP traffic.

### Configuring grpc-gateway

The gateway is configured using [spf13/viper](https://github.com/spf13/viper), see [gwy/templates/config.yaml.tmpl](https://github.com/namely/docker-protoc/blob/master/gwy/templates/config.yaml.tmpl) for configuration options.

To configure your gateway to run under a prefix, set proxy.api-prefix to that prefix. For example, if you have `(google.api.http) = '/foo/bar'`, and set `proxy.api-prefix` to `/api/'`, your gateway will listen to requests on `'/api/foo/bar'`. This can also be set with the environment variable `<SERVICE>_PROXY_API-PREFIX` where `<SERVICE>` is the name of the service generating the gateway.

See [gwy/test.sh](https://github.com/namely/docker-protoc/blob/master/gwy/test.sh) for an example of how to set the prefix with an environment variable.

### HTTP Headers

The gateway will turn any HTTP headers that it receives into gRPC metadata. Any
[permanent HTTP headers](https://github.com/namely/docker-protoc/blob/2e7f0c921984c9d9fc7e42e6a7b9474292f11751/gwy/templates/main.go.tmpl#L61)
will be prefixed with `grpcgateway-` in the metadata, so that your server receives both
the HTTP client-to-gateway headers, as well as the gateway-to-gRPC server headers.

Any headers starting with `Grpc-` will be prefixed with an `X-`; this is because `grpc-` is a reserved metadata prefix.

All other headers will be converted to metadata as-is.

### CORS Configuration

You can configure [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) for your gateway through the
configuration. This will allow your gateway to receive requests from different origins.

There are four values:

*   `cors.allow-origin`: Value to set for Access-Control-Allow-Origin header.
*   `cors.allow-credentials`: Value to set for Access-Control-Allow-Credentials header.
*   `cors.allow-methods`: Value to set for Access-Control-Allow-Methods header.
*   `cors.allow-headers`: Value to set for Access-Control-Allow-Headers header.

For CORS, you will want to configure your `cors.allow-methods` to be the HTTP verbs set in your proto (i.e. `GET`, `PUT`, etc.), as well as `OPTIONS`, so that your service can handle the [preflight request](https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request).

If you are not using CORS, you can leave these configuration values at their default, and your gateway will not accept CORS requests.

### GRPC Client Configuration

*   `grpc.max-call-recv-msg-size`: Sets the maximum message size in bytes the client can receive.

*   `grpc.max-call-send-msg-size`: Sets the maximum message size in bytes the client can send.

### Other Response Headers

You can configure additional headers to be sent in the HTTP response.
Set environment variable with prefix `<SERVICE>_RESPONSE-HEADERS_` (e.g `SOMESERVICE_RESPONSE-HEADERS_SOME-HEADER-KEY`).
You can also set headers in the your configuration file (e.g `response-headers.some-header-key`)

### Marshalling options

#### Setting Marshaler version

By default, `gen-grpc-gateway` will use a marshaler/unmarshaler based on [jsonpb](https://pkg.go.dev/github.com/golang/protobuf/jsonpb). You can change this behavior by setting `gateway.use-jsonpb-v2-marshaler: true`, which will use [protojson](https://pkg.go.dev/google.golang.org/protobuf/encoding/protojson) - a newer version which is more aligned with [proto <=> json mapping](https://developers.google.com/protocol-buffers/docs/proto3#json).

#### Proto names format

By default, `gen-grpc-gateway` will return proto names as they are in the proto messages. You can change this behavior by setting `gateway.use-json-names: true` and the gateway will use camelCase JSON names.

#### Unpopulated fields

By default, `gen-grpc-gateway` will not emit unpopulated fields. You can change this behavior by setting `gateway.emit-unpopulated: true` and the gateway will populate these fields with default values.

#### Unknown fields

By default, `gen-grpc-gateway` will discard unknown fields from requests. You can change this behavior by setting `gateway.keep-unknown: true` and the gateway will keep these fields in the requests.

### Environment Variables

The gateway project used [spf13/viper](https://github.com/spf13/viper) for configuration. The generated gateway code includes a config file that can be overridden with cli flags or environment variables. For environment-variable overrides, use a `<SERVICE>_` prefix, upcase the setting, and replace `.` with `_`.

## grpc\_cli

This repo also contains a Dockerfile for building a `grpc_cli`.

Run it with

```sh
docker run -v `pwd`:/defs --rm -it namely/grpc-cli call docker.for.mac.localhost:50051 \\
LinkShortener.ResolveShortLink "short_link:'asdf'" --protofiles=link_shortener.proto
```

You can pass multiple files to `--protofiles` by separating them with commas, for example
`--protofiles=link_shortener.proto,foo/bar/baz.proto,biz.proto`. All of the protofiles
must be relative to `pwd`, since `pwd` is mounted into the container.

See the [grpc\_cli documentation](https://github.com/grpc/grpc/blob/master/doc/command_line_tool.md)
for more information. You may find it useful to bind this to an alias:

```sh
alias grpc_cli='docker run -v $PWD:/defs --rm -it namely/grpc-cli'
```

Note the use of single quotes in the alias, which avoids expanding the `$PWD` parameter when the alias
is created.

Now you can call it with

```sh
grpc_cli call docker.for.mac.localhost:50051 LinkShortener.ResolveShortLink "short_link:'asdf'" --protofiles=link_shortener.proto
```

## Contributing

Thank you for considering a contribution to namely/docker-protoc!

If you'd like to make an enhancement, or add a container for another language compiler, you will
need to run one of the build scripts in this repo.  You will also need to be running Mac, Linux,
or WSL 2, and have Docker installed.

### Build

From the repository root, run this command to build all the
known containers:

```sh
make build
```

Note the version tag in Docker's console output - this image tag is required to run the tests using
the container with your changes.

You can change some environment variables relevant to the build by setting them as prefixes to the
make command.  For example, this would build the containers using Node.js 15 and gRPC 1.35.  See some
interesting variables in [variables.sh](./variables.sh) and [entrypoint.sh](./all/entrypoint.sh).

```sh
NODE_VERSION=15 GRPC_VERSION=1.35 make build
```

### Test

#### Running tests for `protoc-all` image

To run the tests, identify your image tag from the build step and run `make test` as below:

```sh
CONTAINER=namely/protoc-all:VVV make test
```

(`VVV` is your version from the tag in the console output when running `make build`.) Running this will
demonstrate that your new image can successfully build containers for each language.

Note that testing currently requires [Go](https://go.dev/) to be locally installed.

#### Adding tests

The tests for `protoc-all` are written in Go.\
To add or modify tests, use the testCase struct in [all\_test.go](./all/test/all_test.go) to set:
the language, the arguments to invoke the image with, the expected generated files and any additional assertions.

#### gRPC Gateway test

```sh
CONTAINER=namely/gen-grpc-gateway:VVV make test-gwy
```

### Auto Dependency Managenement

Dependencies are managed in this repo via [Renovate](https://www.mend.io/free-developer-tools/renovate/).
Please read more [here](./.github/renovate.md).

### Release

* A new gRPC version based release is handled automatically once the relevant [Renovate](https://www.mend.io/free-developer-tools/renovate/) branch is merged to master
via the CI (Github Action).  
* A patch/release candidate release should be created manually in Github and the CI workflow will take care of the rest.

#### Contributors

Open a PR and ping one of the Namely employees who have worked on this repo recently.  We will take a look as soon as we can.\
Thank you!!

#### Namely Employees

Namely employees can merge PRs and cut a release/pre-release by drafting a new Github release and publishing them.\
The release name should follow the same tag conventions described in  [this doc](#tag-conventions) and the gRPC version in the release name\
must match the `GRPC_VERSION` configured in [variables.sh](./variables.sh).\
A valid release/pre-release will be of the form `v${GRPC_VERSION}_${BUILD_VERSION}`/`v${GRPC_VERSION}_${BUILD_VERSION}-rc.${RC_VERSION}` respectively.\
e.g `1.37_2`, `1.38_0-rc.3`.\
Once a new **valid** Github release is published, new images will be published to [DockerHub](https://hub.docker.com/u/namely/) via CI.

## Docker Troubleshooting

Docker must be configured to use Linux containers.

If on Windows, you must have your `C:` drive shared with Docker. Open the Docker settings (right-click Docker icon in notification area) and pick the Shared Drives tab. Ensure `C:` is listed and the box is checked. If you are still experiencing trouble, click "Reset credentials..." on that tab and re-enter your local Windows username and password.
