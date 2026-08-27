# A sample Cloud Foundry App in PHP

This App is an example of how to use the [Datadog Cloud Foundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack) to instrument a PHP application with APM tracing and continuous profiling.

## How to build and push

1. For offline Cloud Foundry environments, run `./build.sh` to vendor Composer dependencies into a local `lib/vendor/` folder so the app can stage without reaching packagist.org. Online environments can skip this step — `php_buildpack` runs `composer install` during staging. The `dd-trace-php` native extensions are provided by the Datadog buildpack itself once `DD_APM_INSTRUMENTATION_ENABLED=true` is set.
2. Update the `manifest.yml` file with any other extra configuration options.
3. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`, substituting `<API_KEY>` with your Datadog API key value.
