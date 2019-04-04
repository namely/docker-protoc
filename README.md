# gRPC/Protocol Buffer Compiler Containers

This repository contains support for various Docker images that wrap `protoc`,
`prototool`, `grpc_cli` commands with [gRPC](https://github.com/grpc/grpc) support
in a variety of languages removing the need to install and manage these commands locally. 
It relies on setting a simple volume to the docker container,
usually mapping the current directory to `/defs`, and specifying the file and
language you want to generate.

## Features

* Docker images for:
    * `protoc` with `namely/protoc` (automatically includes `/usr/local/include`)
    * [Uber's Prototool](https://github.com/uber/prototool) with `namely/prototool`
    * A custom generation script to facilitate common use-cases with `namely/protoc-all` (see below)
    * `grpc_cli` with `namely/grpc-cli`
    * [gRPC Gateway](https://github.com/grpc-ecosystem/grpc-gateway) using a custom go-based server with `namely/gen-grpc-gateway`
* [Google APIs](https://github.com/googleapis/googleapis) included in `/usr/local/include/google`
* [Protobuf library artificats](https://github.com/google/protobuf/tree/master/src/google/protobuf) included in `/usr/local/include/google/protobuf`
* Support for all C based gRPC libraries with Go and Java native libraries
*
If you're having trouble, see [Docker troubleshooting](#docker-troubleshooting) below.

> Note - throughout this document, commands for bash are prefixed with `$` and commands
> for PowerShell on Windows are prefixed with `PS>`. It is not required to use "Windows
> Subsystem for Linux" (WSL)

## Tag Conventions

For `protoc`, `grpc_cli` and `prototool` a pattern of <GRPC\_VERSION>_<CONTAINER\_VERSION> is used for all images.
Example is namely/protoc-all:1.15_0 for gRPC version `1.15`. The `latest` tag will always point to the most recent version.

## Usage

Pull the container:

```sh
$ docker pull namely/protoc-all
```

After that, travel to the directory that contains your `.proto` definition
files.

So if you have a directory: `~/my_project/protobufs/` that has:
`myproto.proto`, you'd want to run this:

```sh
$ cd ~/my_project/protobufs
$ docker run -v `pwd`:/defs namely/protoc-all -f myproto.proto -l ruby #or go, csharp, etc
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
_lift_ protofiles up a directory when generating. As an example, say you have a
file `protorepo/catalog/catalog.proto`. This will by default output to
`gen/pb-go/protorepo/catalog/` because `protorepo` is part of the file path
input. To remove the `protorepo` you need to add an include and change the
import:

```
$ docker run ... namely/protoc-all -i protorepo -f catalog/catalog.proto -l go
# instead of
$ docker run ... namely/protoc-all -f protorepo/catalog/catalog.proto -l go
# which will generate files in a `protorepo` directory.
```

## gRPC Gateway (Experimental)

This repo also provides a docker images `namely/gen-grpc-gateway` that
generates a [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway) server.
By annotating your proto (see the grpc-gateway documentation), you can generate a
server that acts as an HTTP server, and a gRPC client to your gRPC service.

Generate a gRPC Gateway docker project with

```
docker run -v `pwd`:/defs namely/gen-grpc-gateway -f path/to/your/proto.proto -s Service
```

where `Service` is the name of your gRPC service defined in the proto. This will create a
folder with a simple go server.
By default, this goes in the `gen/grpc-gateway` folder. You can then build the contents of this
folder into an actual runnable grpc-gateway server.

Build your gRPC Gateway server with

```
docker build -t my-grpc-gateway gen/grpc-gateway/
```

_NOTE_: If your service does not contain any `(google.api.http)` annotations, this build will
fail with an error `...HandlerFromEndpoint is undefined`. You need to have at least one rpc
method annotated to build a gRPC Gateway.

Run this image with

```
docker run my-grpc-gateway --backend=grpc-service:50051
```

where `--backend` refers to your actual gRPC server's address. The gRPC gateway
listens on port 80 for HTTP traffic.

### Configuring grpc-gateway

The gateway is configured using [spf13/viper](https://github.com/spf13/viper), see [gwy/templates/config.yaml.tmpl](https://github.com/namely/docker-protoc/blob/master/gwy/templates/config.yaml.tmpl) for configuration options.

To configure your gateway to run under a prefix, set proxy.api-prefix to that prefix. For example, if you have `(google.api.http) = '/foo/bar'`, and set `proxy.api-prefix` to `/api/'`, your gateway will listen to requests on `'/api/foo/bar'`. This can also be set with the environment variable `<SERVICE>_PROXY_API-PREFIX` where `<SERVICE>` is the name of the service generating the gateway. 

See [gwy/test.sh](https://github.com/namely/docker-protoc/blob/master/gwy/test.sh) for an example of how to set the prefix with an environment variable.

### HTTP Headers

The gateway will turn any HTTP headers that it receives into gRPC metadata. Any
[permanent HTTP headers](https://github.com/namely/docker-protoc/blob/2e7f0c921984c9d9fc7e42e6a7b9474292f11751/gwy/templates/main.go.tmpl#L61)
will be prefixed with 'grpcgateway-' in the metadata, so that your server receives both
the HTTP client to gateway headers, as well as the gateway to gRPC server headers.

Any headers starting with 'Grpc-' will be prefixed with an 'X-', this is because 'grpc-' is a reserved metadata prefix.

All other headers will be converted to metadata as is.

### CORS Configuration.

You can configure [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) for your gateway through the
configuration. This will allow your gateway to receive requests from different origins.

There are four values:

- `cors.allow-origin`: Value to set for Access-Control-Allow-Origin header.
- `cors.allow-credentials`: Value to set for Access-Control-Allow-Credentials header.
- `cors.allow-methods`: Value to set for Access-Control-Allow-Methods header.
- `cors.allow-headers`: Value to set for Access-Control-Allow-Headers header.

    For CORS, you will want to configure your `cors.allow-methods` to be the HTTP verbs set in your proto (i.e. `GET`, `PUT`, etc.), as well as `OPTIONS`, so that your service can handle the [preflight request](https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request).

    If you are not using CORS, you can leave these configuration values at their default, and your gateway will not accept CORS requests.
###  Other Response Headers

You can configure additional headers to be sent in the HTTP response.  
Set environment variable with prefix `<SERVICE>_RESPONSE-HEADERS_` (e.g `SOMESERVICE_RESPONSE-HEADERS_SOME-HEADER-KEY`).  
You can also set headers in the your configuration file (e.g `response-headers.some-header-key`)

### Environment Variables

The gateway project used [spf13/viper](https://github.com/spf13/viper) for configuration. The generated gateway code includes a config file that can be overridden with cli flags or environment variables. For environment variable overrides use a `<SERVICE>_` prefix, upcase the setting, and replace `.` with `_`.

## grpc_cli

This repo also contains a Dockerfile for building a grpc_cli.

Run it with

```sh
docker run -v `pwd`:/defs --rm -it namely/grpc-cli call docker.for.mac.localhost:50051 \\
LinkShortener.ResolveShortLink "short_link:'asdf'" --protofiles=link_shortener.proto
```

You can pass multiple files to --protofiles by separating them with commas, for example
`--protofiles=link_shortener.proto,foo/bar/baz.proto,biz.proto`. All of the protofiles
must be relative to pwd, since pwd is mounted into the container.

See the [grpc_cli documentation](https://github.com/grpc/grpc/blob/master/doc/command_line_tool.md)
for more information. You may find it useful to bind this to an alias:

```sh
alias grpc_cli='docker run -v `pwd`:/defs --rm -it namely/grpc-cli'
```

Note the use of single quotes in the alias, which avoids expanding the `pwd` parameter when the alias
is created.

Now you can call it with

```sh
grpc_cli call docker.for.mac.localhost:50051 LinkShortener.ResolveShortLink "short_link:'asdf'" --protofiles=link_shortener.proto
```

## Contributing

If you make changes, or add a container for another language compiler, this repo
has simple scripts that can build projects. You can run the following within the
all/ folder:

```sh
$ make build
```

This will build all of the known containers.

```sh
$ CONTAINER=namely/protoc-all:VVV make test
```

Where VVV is your version. This will run tests that containers can build for each language.

```sh
$ make push
```

This will build and push the containers to the Namely registry located on
[DockerHub](https://hub.docker.com/u/namely/). You must be authorized to push to
this repo.

## Docker Troubleshooting

Docker must be configured to use Linux containers.

If on Windows, you must have your C: drive shared with Docker. Open the Docker settings (right-click Docker icon in notification area) and pick the Shared Drives tab. Ensure C is listed and the box is checked. If you are still experiencing trouble, click "Reset credentials..." on that tab and re-enter your local Windows username and password.
