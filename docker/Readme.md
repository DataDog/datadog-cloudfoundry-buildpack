# Using Datadog with Docker in Cloud Foundry

Cloud Foundry also supports running Docker containers. Setting up Datadog to monitor your Docker containers is done via the Dockerfile instead of a buildpack, as buildpacks are unsupported.

The following example coveres a simple flask app and provides more detail on how to get started.

## Dockerfile

This Dockerfile demonstrates setting up the Datadog assets, sample flask app, and an entrypoint file.

## Flask app

A simple flask application demonstrating examples on tracing, dogstatsd and logs. The requirements.txt file contains the dependencies.

## Entrypoint

The entrypoint file has the two Datadog scripts sourced, instead of them being run directly. By having them sourced, they aren't blocking on the main script.
