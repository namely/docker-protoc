#!/bin/bash
set -e

# This script wraps grpc_cli so we can do some setup before running it.

# Since we have mounted /defs to a directory on the user's host machine, we can't
# create symlinks there, or they will be created on the host machine. So symlink
# everything into the /run directory, and run grpc_cli from there.

ln -sf /defs/* /run/
ln -sf /opt/include/google /run/
ln -sf /opt/include/protoc-gen-openapiv2 /run/

grpc_cli "$@"
