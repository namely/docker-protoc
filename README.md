# Protocol Buffer Compiler Containers

This repository contains the Dockerfile for generating gRPC and protobuf
code for various languages, removing the need to setup protoc and the
various gRPC plugins lcoally. It relies on setting a simple volume to the 
docker container, usually mapping the current directory to `/defs`,
and specifying the file and language you want to generate. 

## Usage

Pull the container:

```sh
$ docker pull namely/protoc-all
```

After that, travel to the directory that contains your `.proto` definition files.


So if you have a directory: `/Users/me/project/protobufs/` that has:
`myproto.proto`, you'd want to do this:

```sh
cd ~/my_project/protobufs
docker run -v `pwd`:/defs namely/protoc-all -f myproto.proto -l ruby #or go, csharp, etc
```

The container automatically puts the compiled files into a `gen` directory with language-specific sub-directories. So
for Golang, the files go into a directory `./gen/pb-go`; For ruby the directory is `./gen/pb-ruby`.

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
