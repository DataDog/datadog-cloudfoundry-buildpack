# A sample Cloud Foundry App in Go

This App is an example of how to use the [Datadog Cloud Foundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack).

This sample Go application for Cloud Foundry sends metrics, logs, and traces to Datadog.

### How to push the app

1. Edit the `manifest.yml` with your Datadog credentials.
2. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`, substituting `<API_KEY>` with your Datadog API key value.

### How to run locally

1. Build the app: `./build.sh`. This creates a `main` binary.
2. Run the app with `./main`.
