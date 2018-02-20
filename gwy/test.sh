#!/bin/bash

CONTAINER=$1

# Test building the gateway.
docker run --rm -v=`pwd`:/defs $CONTAINER -f test/test.proto -s Message

# And make sure that we can build the test gateway too.
docker build -t $CONTAINER-test-gateway gen/grpc-gateway/

