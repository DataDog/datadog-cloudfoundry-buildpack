# Using Datadog with Docker in Cloud Foundry

Cloud Foundry also supports running Docker containers. Setting up Datadog to monitor your Docker containers is done via the Dockerfile instead of a buildpack, as buildpacks are unsupported. This provides a mechanism to add the buildpack to the dockerfile.

The following example coveres a simple flask app and provides more detail on how to get started.

## [Dockerfile](Dockerfile)

This Dockerfile demonstrates setting up the Datadog assets, sample flask app, and an entrypoint file. As a note, the buildpack requires Python in order to work correctly.

## [Flask app](app)

A simple flask application demonstrating examples on tracing, dogstatsd and logs. The requirements.txt file contains the dependencies.

## [Entrypoint](entrypoint.sh)

The entrypoint file has the two Datadog scripts sourced, instead of them being run directly. By having them sourced, they aren't blocking on the main script.
