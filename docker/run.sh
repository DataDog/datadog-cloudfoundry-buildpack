#!/bin/bash

# This is a simple script to run the application.
# Used only for testing your docker image locally.
# You will need to have the ${DD_API_KEY} available in order to run it

docker run --rm \
  -e DD_API_KEY="${DD_API_KEY}" \
  -e PORT=5050 \
  -p 5050:5050 \
  docker_app_with_buildpack
