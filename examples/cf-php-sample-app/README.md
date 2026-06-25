# A sample Cloud Foundry App in PHP

This App is an example of how to use the [Datadog Cloud Foundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack) to instrument a PHP application with APM tracing and continuous profiling.

## How to build and push

1. Run `./build.sh` to vendor Composer dependencies into a local `vendor/` folder so the app can be staged on offline Cloud Foundry environments. The script uses a local `composer` if present, otherwise runs it in the official `composer` Docker image, so no local PHP toolchain is required. The `dd-trace-php` native extensions are provided by the Datadog buildpack itself once `DD_APM_INSTRUMENTATION_ENABLED=true` is set.
   - On online environments this step is optional: skip it and push directly, and the `php_buildpack` runs Composer during staging.
2. Update the `manifest.yml` file with any other extra configuration options.
3. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`, substituting `<API_KEY>` with your Datadog API key value.
