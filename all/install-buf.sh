#!/bin/bash -e

# Substitute BIN for your bin directory.
# Substitute VERSION for the current released version.
# Substitute BINARY_NAME for "buf", "protoc-gen-buf-check-breaking", or "protoc-gen-buf-check-lint".
echo ${BUF_VERSION}
echo version
BIN="/usr/local/bin" && \
BINARY_NAME="buf" && \
  curl -sSL \
    "https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/${BINARY_NAME}-$(uname -s)-$(uname -m)" \
    -o "${BIN}/${BINARY_NAME}" && \
  chmod +x "${BIN}/${BINARY_NAME}"
