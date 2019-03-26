#!/bin/bash

DOCKER_DIR=$(cd "$(dirname $0)/." && pwd)

ROOT_DIR="$DOCKER_DIR/.."

# First, build the buildpack.
# The build script is the easiest way to get the buildpack assets

# if [ -z "$DO_NOT_BUILD" ]; then
#   pushd $ROOT_DIR
#     NO_ZIP=true REFRESH_ASSETS=true ./build
#   popd
# fi

docker build $ROOT_DIR -t docker_app_with_buildpack -f $DOCKER_DIR/Dockerfile
