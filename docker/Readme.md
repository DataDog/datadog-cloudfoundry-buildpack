# Docker in PCF

If you're using docker in PCF, you can't use the buildpack. This and the accompinying dockerfile will provide a guide to adding something very similar to this buildpack to your docker images.

## Dockerfile

The dockerfile contains both the datadog assets as well as a small flask app, and shows you how to set up an entrypoint file to start all of these things

## Flask app

This is a simple flask application demonstrating examples on tracing, dogstatsd and logs. The requirements.txt file contains the dependencies.

## Entrypoint

The entrypoint file has the two Datadog scripts sourced, instead of them being run directly. Having them sourced means that they aren't blocking on the main script.
