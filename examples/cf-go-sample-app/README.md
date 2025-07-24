# A sample Cloud Foundry App in Go

This App is an example of how to use the [Datadog Cloudfoundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack).

Sample go application for CloudFoundry that sends metrics, logs, and traces to Datadog.

### How to push the app

1. Edit the `manifest.yml` with your DD credentials
2. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`

### How to run locally

1. Build the app: `./build.sh`. This will create a `main` binary.
2. Run the app with `./main`
