# A sample Cloud Foundry App in Python

This App is an example of how to use the [Datadog Cloud Foundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack).

## How to build and push

1. Update the `manifest.yml` file with any other extra configuration options.
2. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`, substituting `<API_KEY>` with your Datadog API key value.
