# Protocol Buffer Compiler Containers

This repository contains the Dockerfile for generating gRPC and protobuf code
for various languages, removing the need to setup protoc and the various gRPC
plugins lcoally. It relies on setting a simple volume to the docker container,
usually mapping the current directory to `/defs`, and specifying the file and
language you want to generate.

## Usage

Pull the container:

```sh
$ docker pull namely/protoc-all
```

After that, travel to the directory that contains your `.proto` definition
files.

So if you have a directory: `/Users/me/project/protobufs/` that has:
`myproto.proto`, you'd want to do this:

```sh
cd ~/my_project/protobufs
docker run -v `pwd`:/defs namely/protoc-all -f myproto.proto -l ruby #or go, csharp, etc
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

This repo also provides a script `all/generate_gateway.sh` that will generate an
Docker image of a [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway)
for your proto. Run it locally, specifying your proto file, the name of your
gRPC service (we could figure it out by parsing the proto file, but for now this
is easier), and the name of the Docker container to generate.

The container is a stand-alone app that acts as an HTTP server and a gRPC client
for your service. Run it with "docker run my-container --backend=grpc-service:50051",
where --backend refers to your actual gRPC server's address.


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
