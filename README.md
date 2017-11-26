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

You can optionally specify `--with-gateway` to generate
[grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway) support with
swagger. Ideally this will generate a ready-to-go containerized app, but for now
you can access the generated gateway code and swagger definition.

## Contributing

If you make changes, or add a container for another language compiler, this repo
has simple scripts that can build projects. You can run:

```sh
$ ./build.sh [-t <tag name>]
```

This will build all of the known containers.

```sh
$ ./push.sh
```

This will build and push the containers to the Namely registry located on
[DockerHub](https://hub.docker.com/u/namely/).
