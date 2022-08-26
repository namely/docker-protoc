#!/bin/bash
set -ef

CONTAINER=${CONTAINER}

if [ -z "${CONTAINER}" ]; then
    echo "You must specify a build container with \${CONTAINER} to test (see my README.md)"
    exit 1
fi

cd all/test
go test -v all_test.go
