#!/bin/bash

docker run \
  -e DD_API_KEY="$DD_API_KEY" \
  -p 5000:5000 \
  docker_app_with_buildpack
