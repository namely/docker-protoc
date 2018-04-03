#!/bin/bash
set -e
set -x

CONTAINER=$1

# Test building the gateway.
docker run --rm -v=`pwd`:/defs $CONTAINER -f test/test.proto -s Message

# And make sure that we can build the test gateway too.
docker build -t $CONTAINER-test-gateway gen/grpc-gateway/

# Now run the test container with a prefix in the background
docker run -p=8080:80 -e 'MESSAGE_PROXY_API-PREFIX=/api/' $CONTAINER-test-gateway &

# Give it a few to start accepting requests
sleep 5

# Now use curl to make sure we get an expected status.
# From https://superuser.com/a/442395
status=`curl -s -o /dev/null -w "%{http_code}" localhost:8080/api/messages`

# For now, we expect a 503 service unavailable, since we don't have a grpc service
# running. In the future, if this was a real backend we should get a 200. However,
# here we can use the 503 to indicate that the gateway tried to send the request
# downstream.
if [ "$status" -ne "503" ]; then
  kill $1
  echo "Invalid status: '$status'"
  exit 1
fi

# If we call an endpoint that does not exist (say just messages), we should
# get a 404, since there's no handler for that endpoint.
status=`curl -s -o /dev/null -w "%{http_code}" localhost:8080/messages`
if [ "$status" -ne "404" ]; then
  kill $1
  echo "Invalid status: '$status'"
  exit 1
fi

kill $!


