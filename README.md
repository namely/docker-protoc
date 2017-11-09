# Protocol Buffer Compiler Containers

This repository contains Dockerfiles that build protocol buffer generation
scripts for Go and Ruby. Removing the need to setup Protoc (v3) on your
local machine. It relies on setting a simple volume to the docker container,
and it will take care of the rest.

## Usage

Pull the container for the language you want to compile:

```sh
$ docker pull namely/protoc-ruby

# OR

$ docker pull namely/protoc-go
```

After that, travel to the directory that contains your `.proto` definition files.


So if you have a directory: `/Users/me/project/protobufs/` that has:
`myproto.proto`, you'd want to do this:

```sh
cd ~/my_project/protobufs
docker run -v `pwd`:/defs namely/protoc-ruby
```

The container automatically puts the compiled files into directories for each language. So
for Golang, the files go into a directory "pb-go"; For ruby the directory is "pb-ruby".

### Supported GRPC Plugins
- [x] Ruby
- [x] Go
- [x] Objective-C
- [x] C#
- [x] Java
- [x] Php

### Profit.

That's it.

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
