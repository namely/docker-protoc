Template files for generating a GRPC gateway server.

1. config.yaml.tmpl is the Viper configuration for the server.
1. main.go.tmpl is the entrypoint for the generated server.
1. Dockerfile.tmpl is the Dockerfile that can be used to generate a server image.

These files are used to build a grpc-gateway server with `namely/gen-grpc-gateway`.

The files contain the following substitutions:

1. ${SERVICE} - the name of the service in the proto.
1. ${SWAGGER\_FILE\_NAME} - the name of the swagger file.

The templates are copied into the `/templates` folder in the `namely/gen-grpc-gateway`
image.
