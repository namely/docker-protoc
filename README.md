# gRPC/Protocol Buffers Container Toolkit

This repo builds a docker container the `protoc` command line utility, several gRPC plugins, and
several grpc tools. It is meant to provide a swiss army knife docker container for all your gRPC
needs. In multi-team environments this is essential to provide specific configurations to teammates.

## Features

- Docker images for:
  - `grpckit` a default container with all the goodies
  - `protoc` with `grpckit/protoc`
  - `buf`, containing the https://buf.build/ toolkit.
- ## Support for all C based gRPC libraries
- Go, including Gogo, Gogo Fast and Micro
- Scala and Java native libraries
- grpc-web
- The following additions:
  - protoc-gen-lint
  - protoc-gen-doc
  - protoc-gen-validate
  - protoc-gen-govalidators
  - protoc-gen-rbi (Ruby Sorbet Types)
  - renderizer

If you're having trouble, see [Docker troubleshooting](#docker-troubleshooting) below.

## Tag Conventions

A tag pattern of `<GRPC\_VERSION>_<CONTAINER\_VERSION>` is used for all images.
Example is `grpckit/protoc-all:1.28_0` for gRPC version `1.28`. The `_0` suffix allows for inter-grpc releases as necessary. The `latest` tag will always point to the most recent version.

It is highly recommend to pin to a specific gRPC version in your toolchain for repeatable builds.

## Protorepo Includes

Unlike the original [namely/docker-protoc](https://github.com/namely/docker-protoc), this repo does not include extraneous
proto files like the Google APIs, or protos from plugin binaries like `validator`. These protos should be included
with your source protos, preferably in a protorepo (a monorepo for protofiles) that's submoduled into your project.
In practice, assuming the system has proto files available outside the standard protobuf files fails, so it's
best to be explicit.

## Contributing

If you make changes, or add a container for another language compiler, this repo
has simple scripts that can build projects. You can run the following within the
all/ folder:

```sh
$ make build
```

This will build all of the known containers.

```sh
$ make push
```

This will build and push the containers to the org specified in variables.sh.
