# gRPC/Protocol Buffer Compiler Containers

This repository contains support for various Docker images that wrap `protoc`,
`prototool`, `grpc_cli` commands with [gRPC](https://github.com/grpc/grpc) support
in a variety of languages removing the need to install and manage these commands locally.
It relies on setting a simple volume to the docker container,
usually mapping the current directory to `/defs`, and specifying the file and
language you want to generate.

## Features

- Docker images for:
  - `grpckit` a default container with all the goodies
  - `protoc` with `grpckit/protoc`
- Support for all C based gRPC libraries with Go and Java native libraries

If you're having trouble, see [Docker troubleshooting](#docker-troubleshooting) below.

> Note - throughout this document, commands for bash are prefixed with `$` and commands
> for PowerShell on Windows are prefixed with `PS>`. It is not required to use "Windows
> Subsystem for Linux" (WSL)

## Tag Conventions

For `protoc` a pattern of `<GRPC\_VERSION>_<CONTAINER\_VERSION>` is used for all images.
Example is `grpckit/protoc-all:1.28_0` for gRPC version `1.28`. The `_0` suffix allows for inter-grpc releases as necessary. The `latest` tag will always point to the most recent version.

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

## Docker Troubleshooting

Docker must be configured to use Linux containers.

If on Windows, you must have your `C:` drive shared with Docker. Open the Docker settings (right-click Docker icon in notification area) and pick the Shared Drives tab. Ensure `C:` is listed and the box is checked. If you are still experiencing trouble, click "Reset credentials..." on that tab and re-enter your local Windows username and password.
