# Datadog Cloud Foundry Buildpack

This is a [supply buildpack](https://docs.cloudfoundry.org/buildpacks/understand-buildpacks.html#supply-script) for Cloud Foundry. It installs the following three binaries in the container your application is running on:
* Datadog Dogstatsd for submitting custom metrics from your application
* Datadog Trace Agent for submitting APM traces from your application
* Datadog IoT Agent for submitting your application logs

## Installation

### Upload the buildpack to CF

Download the latest Datadog [buildpack release](https://cloudfoundry.datadoghq.com/datadog-cloudfoundry-buildpack/datadog-cloudfoundry-buildpack-latest.zip) or [build it](/DEVELOPMENT.md#building) and upload it to your Cloud Foundry environment.

- Upload buildpack for the first time
    ```bash
    cf create-buildpack datadog-cloudfoundry-buildpack datadog-cloudfoundry-buildpack.zip 99 --enable
    ```
- Update existing buildpack
    ```bash
    cf update-buildpack datadog-cloudfoundry-buildpack -p datadog-cloudfoundry-buildpack.zip
    ```
Once it is available in your Cloud Foundry environment, configure your application to use the Datadog buildpack by specifying it in your application manifest.

**Note:** since this is a supply buildpack, it has to be specified before any final buildpack in the list. See [here](https://docs.cloudfoundry.org/buildpacks/use-multiple-buildpacks.html) for details about pushing an application with multiple buildpacks.

### Configuration

#### Metric Collection

Set an API Key in your environment to enable the Datadog Agents in the buildpack. The following code samples specify the `env` section of the application manifest.

```yaml
env: 
  DD_API_KEY: <DATADOG_API_KEY>
```

#### Log Collection

**Enable log collection**

To start collecting logs from your application in CloudFoundry, the Agent contained in the buildpack needs to be activated and log collection enabled.

```yaml
env: 
  DD_API_KEY: <DATADOG_API_KEY>
  RUN_AGENT: true
  DD_LOGS_ENABLED: true
  # Disable the Agent core checks to disable system metrics collection
  DD_ENABLE_CHECKS false
  # Redirect Container Stdout/Stderr to a local port so the agent can collect the logs
  STD_LOG_COLLECTION_PORT: <PORT>
  # Configure the agent to collect logs from the wanted port and set the value for source and service
  LOGS_CONFIG: '[{"type":"tcp","port":"<PORT>","source":"<SOURCE>","service":"<SERVICE>"}]'
```

**Configure log collection**

The following environment variables are used to configure log collection.

- `STD_LOG_COLLECTION_PORT`: Must be used when collecting logs from `stdout`/`stderr`. It redirects the `stdout`/`stderr` stream to the corresponding local port value.
- `LOGS_CONFIG`: Use this option to configure the agent to listen to a local TCP port and set the value for the `service` and `source` parameters. The port specified in the configuration must be the same as specified in the environment variable `STD_LOG_COLLECTION_PORT`.

**Example**

An `app01` Java application is running in Cloud Foundry. The following configuration redirects the container `stdout`/`stderr` to the local port 10514. It then configures the Agent to collect logs from that port while setting the proper value for `service` and `source`:

```yaml
env:
  DD_API_KEY: <DATADOG_API_KEY>
  RUN_AGENT: true
  DD_LOGS_ENABLED: true
  DD_ENABLE_CHECKS false
  STD_LOG_COLLECTION_PORT: 10514
  LOGS_CONFIG '[{"type":"tcp","port":"10514","source":"java","service":"app01"}]'
```

#### General configuration of the Datadog Agent
All the options supported by the Agent in the main `datadog.yaml` configuration file can also be set through environment variables as described in the [documentation of the Agent](https://github.com/DataDog/datadog-agent/blob/master/docs/agent/config.md#environment-variables).

### Instrument your application
You are all set up to instrument your application and start sending custom metrics and APM traces through DogStatsD and the Datadog Trace Agent.
Download and import [the relevant libraries](https://docs.datadoghq.com/libraries/) and start sending data! To learn more, check out our [DogSatsD documentation](https://docs.datadoghq.com/guides/DogStatsD/) and [APM documentation](https://docs.datadoghq.com/tracing/setup_overview/).

## Docker

If you're running docker on Cloud Foundry, you can look at [the docker directory](docker/) to see how to adapt this buildpack to use in a dockerfile.
