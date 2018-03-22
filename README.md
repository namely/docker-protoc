# Protocol Buffer Compiler Containers

This repository contains the Dockerfile for generating gRPC and protobuf code
for various languages, removing the need to setup protoc and the various gRPC
plugins lcoally. It relies on setting a simple volume to the docker container,
usually mapping the current directory to `/defs`, and specifying the file and
language you want to generate.

If you're having trouble, see [Docker troubleshooting](#docker-troubleshooting) below.

> Note - throughout this document, commands for bash are prefixed with `$` and commands
> for PowerShell on Windows are prefixed with `PS>`.  It is not required to use "Windows
> Subsystem for Linux" (WSL)

## Usage

Pull the container:

```sh
$ docker pull namely/protoc-all:1.9
```

After that, travel to the directory that contains your `.proto` definition
files.

So if you have a directory: `~/my_project/protobufs/` that has:
`myproto.proto`, you'd want to run this:

```sh
$ cd ~/my_project/protobufs
$ docker run -v `pwd`:/defs namely/protoc-all:1.9 -f myproto.proto -l ruby #or go, csharp, etc
```

```powershell
PS> cd ~/my_project/protobufs
PS> docker run -v ${pwd}:/defs namely/protoc-all:1.9 -f myproto.proto -l ruby #or go, csharp, etc
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
$ docker run ... namely/protoc-all:1.9 -i protorepo -f catalog/catalog.proto -l go
# instead of
$ docker run ... namely/protoc-all:1.9 -f protorepo/catalog/catalog.proto -l go
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
folder with a simple go  server.
By default, this goes in the `gen/grpc-gateway` folder. You can then build the contents of this
folder into an actual runnable grpc-gateway server.

Build your gRPC Gateway server with 
```
docker build -t my-grpc-gateway gen/grpc-gateway/
```

*NOTE*: If your service does not contain any `(google.api.http)` annotations, this build will
fail with an error `...HandlerFromEndpoint is undefined`. You need to have at least one rpc
method annotated to build a gRPC Gateway.

Run this image with

```
docker run my-grpc-gateway --backend=grpc-service:50051
```

where `--backend` refers to your actual gRPC server's address. The gRPC gateway 
listens on port 80 for HTTP traffic.

## grpc\_cli

This repo also contains a Dockerfile for building a grpc\_cli. 

Run it with

```sh
docker run -v `pwd`:/defs --rm -it namely/grpc-cli call docker.for.mac.localhost:50051 \\
   LinkShortener.ResolveShortLink "short_link:'asdf'" --protofiles=link_shortener.proto
```

You can pass multiple files to --protofiles by separating them with commas, for example
`--protofiles=link_shortener.proto,foo/bar/baz.proto,biz.proto`. All of the protofiles
must be relative to pwd, since pwd is mounted into the container.

See the [grpc\_cli documentation](https://github.com/grpc/grpc/blob/master/doc/command_line_tool.md)
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
$ make test
```

This will run tests that containers can build for each language.

```sh
$ make push
```

This will build and push the containers to the Namely registry located on
[DockerHub](https://hub.docker.com/u/namely/). You must be authorized to push to
this repo.


## Docker Troubleshooting

Docker must be configured to use Linux containers.

If on Windows, you must have your C: drive shared with Docker.  Open the Docker settings (right-click Docker icon in notification area) and pick the Shared Drives tab.  Ensure C is listed and the box is checked.  If you are still experiencing trouble, click "Reset credentials..." on that tab and re-enter your local Windows username and password.
