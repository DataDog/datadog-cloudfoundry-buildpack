#!/bin/bash

docker run --rm \
  -e DD_API_KEY="$DD_API_KEY" \
  -e PORT=5050 \
  -p 5050:5050 \
  docker_app_with_buildpack
