#!/bin/bash 
set -e

CONTAINER=${CONTAINER}

if [ -z "${CONTAINER}" ]; then
    echo "You must specify a build container with \${CONTAINER} to test (see my README.md)"
    exit 1
fi

HEADERS_FILE="./.headers"
SOME_RESP_HEADER="SOME-RESPONSE-HEADER"

pushd "gwy"

# Test building the gateway.
docker run --rm -v="$PWD":/defs "$CONTAINER" -f /defs/test/test.proto -i /defs -s Message

# And make sure that we can build the test gateway too.
docker build -t $CONTAINER-test-gateway gen/grpc-gateway/

# Now run the test container with a prefix in the background
docker run -p=8080:80 -e 'MESSAGE_PROXY_API-PREFIX=/api/' -e 'MESSAGE_RESPONSE-HEADERS_'${SOME_RESP_HEADER}'=some-value' $CONTAINER-test-gateway &

# Give it a few to start accepting requests
sleep 5

# Now use curl to make sure we get an expected status.
# From https://superuser.com/a/442395
status=`curl -i -s -o $HEADERS_FILE -w "%{http_code}" localhost:8080/api/messages`

# For now, we expect a 503 service unavailable, since we don't have a grpc service
# running. In the future, if this was a real backend we should get a 200. However,
# here we can use the 503 to indicate that the gateway tried to send the request
# downstream.
echo ""
if [ "$status" -ne "503" ]; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when no backend service running"
  echo >&2 "Invalid status: '$status' with /api/messages http request"
  exit 1
fi

if ! grep -qi "$SOME_RESP_HEADER" "$HEADERS_FILE"; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when no backend service running"
  echo >&2 "header $SOME_RESP_HEADER was not found in response"
  rm $HEADERS_FILE
  exit 1
fi
echo "[Pass] - Received expected response from gateway when no backend service running"
rm $HEADERS_FILE

# If we call an endpoint that does not exist (say just messages), we should
# get a 404, since there's no handler for that endpoint.
status=`curl -s -o /dev/null -w "%{http_code}" localhost:8080/messages`

echo ""
if [ "$status" -ne "404" ]; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when grpc method does not exist"
  echo >&2 "Invalid status: '$status' with /messages http request"
  exit 1
fi
echo "[Pass] - Received expected response from gateway when grpc method does not exist"

# UnboundUnary should not work
# Unbound methods require the request payload as request body (curl --data 'payload')
status=`curl -s -o /dev/null -w "%{http_code}" --data '{}' localhost:8080/api/Messages.Message/UnboundUnary`

echo ""
if [ "$status" -ne "404" ]; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when expected payload not passed in the http request body"
  echo >&2 "Invalid status: '$status' with /api/Messages.Message/UnboundUnary http request"
  exit 1
fi
echo "[Pass] - Received expected response from gateway when expected payload not passed in the http request body"

kill $!

# Test building the gateway with unbound methods.
docker run --rm -v="$PWD":/defs "$CONTAINER" -f test/test.proto -i . -s Message --generate-unbound-methods

# And make sure that we can build the test gateway too.
docker build -t $CONTAINER-test-gateway gen/grpc-gateway/

# Now run the test container with a prefix in the background
docker run -p=8080:80 -e 'MESSAGE_PROXY_API-PREFIX=/api/' -e 'MESSAGE_RESPONSE-HEADERS_'${SOME_RESP_HEADER}'=some-value' $CONTAINER-test-gateway &

# Give it a few to start accepting requests
sleep 5

# Now use curl to make sure we get an expected status.
# From https://superuser.com/a/442395
status=`curl -i -s -o $HEADERS_FILE -w "%{http_code}" localhost:8080/api/messages`

# For now, we expect a 503 service unavailable, since we don't have a grpc service
# running. In the future, if this was a real backend we should get a 200. However,
# here we can use the 503 to indicate that the gateway tried to send the request
# downstream.
echo ""
if [ "$status" -ne "503" ]; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when no backend service running, and unbound methods are generated"
  echo >&2 "Invalid status: '$status' with /api/messages http request"
  exit 1
fi
echo "[Pass] - Received expected response from gateway when no backend service running, and unbound methods are generated"

# UnboundUnary should work
# Unbound methods require the request payload as request body (curl --data 'payload')
status=`curl -i -s -o $HEADERS_FILE -w "%{http_code}" --data '{}' localhost:8080/api/Messages.Message/UnboundUnary`

echo ""
if [ "$status" -ne "503" ]; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when no backend service running and calling an unbound method, and unbound methods are generated"
  echo >&2 "Invalid status: '$status' with /api/Messages.Message/UnboundUnary http request"
  exit 1
fi

if ! grep -qi "$SOME_RESP_HEADER" "$HEADERS_FILE"; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when no backend service running and calling an unbound method, and unbound methods are generated"
  echo >&2 "header $SOME_RESP_HEADER was not found in response"
  rm $HEADERS_FILE
  exit 1
fi
rm $HEADERS_FILE
echo "[Pass] - Received expected response from gateway when no backend service running and calling an unbound method, and unbound methods are generated"

# If we call an endpoint that does not exist (say just messages), we should
# get a 404, since there's no handler for that endpoint.
status=`curl -s -o /dev/null -w "%{http_code}" localhost:8080/messages`

echo ""
if [ "$status" -ne "404" ]; then
  kill $!
  echo >&2 "[Fail] - Received expected response from gateway when grpc method does not exist, and unbound methods are generated"
  echo >&2 "Invalid status: '$status' with /messages http request"
  exit 1
fi
echo "[Pass] - Received expected response from gateway when grpc method does not exist, and unbound methods are generated"

kill $!
