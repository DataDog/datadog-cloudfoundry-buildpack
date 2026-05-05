# A sample Cloud Foundry App in PHP

This App is an example of how to use the [Datadog Cloud Foundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack) to instrument a PHP application with APM tracing and continuous profiling.

## How to build and push

1. Run `./build.sh` to vendor Composer dependencies into a local `vendor/` folder and to download the `dd-trace-php` native extensions into `extensions/` so the app can be staged on offline Cloud Foundry environments.
2. Update the `manifest.yml` file with any other extra configuration options.
3. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`, substituting `<API_KEY>` with your Datadog API key value.
