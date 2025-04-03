# Datadog Cloud Foundry Buildpack

This is a [supply buildpack][1] for Cloud Foundry. It installs the following three binaries in the container your application is running on:
* Datadog Dogstatsd for submitting custom metrics from your application
* Datadog Trace Agent for submitting APM traces from your application
* Datadog IoT Agent for submitting your application logs

## Basic Usage

If you don't have this buildpack uploaded in your foundation, you can reference one
of the GitHub .zip releases in your `manifest.yml`, like this:

```
---
applications:
- name: test-python-flask
  random-route: true
  buildpacks:
    - https://github.com/DataDog/datadog-cloudfoundry-buildpack/releases/download/4.42.0/datadog-cloudfoundry-buildpack.zip
    - python_buildpack
  memory: 256M
  stack: cflinuxfs4
  env:
    DD_API_KEY: <DATADOG_API_KEY>  
```

## Installation

### Upload the buildpack to CF

Download the latest Datadog [buildpack release][2] or [build it][3] and upload it to your Cloud Foundry environment.

- Upload buildpack for the first time
    ```bash
    cf create-buildpack datadog-cloudfoundry-buildpack datadog-cloudfoundry-buildpack.zip 99 --enable
    ```
- Update existing buildpack
    ```bash
    cf update-buildpack datadog-cloudfoundry-buildpack -p datadog-cloudfoundry-buildpack.zip
    ```
Once it is available in your Cloud Foundry environment, configure your application to use the Datadog buildpack by specifying it in your application manifest.

**Note**: Since this is a supply buildpack, it has to be specified before any final buildpack in the list. See [Cloud Foundry documentation][4] for details about pushing an application with multiple buildpacks.

## Configuration

### General configuration of the Datadog Agent
All options supported by the Agent in the main `datadog.yaml` configuration file can also be set through environment variables as described in the [Agent documentation][5].

#### Setup the Datadog API Key

Set an API Key in your environment to enable the Datadog Agents in the buildpack. The following code samples specify the `env` section of the application manifest.

```yaml
env:
  DD_API_KEY: <DATADOG_API_KEY>
```

#### Assigning Tags

For an overview about tags, read [Getting Started with Tags](https://docs.datadoghq.com/getting_started/tagging/).

Custom tags can be configured with the environment variable `DD_TAGS`. These tags will be attached to the application logs, metrics, and traces as span tags.

By default, `DD_TAGS` is expected to be a comma separated list of tags.

```yaml
env:
  DD_TAGS: "key1:value1,key2:value2,key3:value3"
```

To use a different separator, set `DD_TAGS_SEP` to the desired separator.

```yaml
env:
  DD_TAGS: "key1:value1 key2:value2 key3:value3"
  DD_TAGS_SEP: " "
```

### Instrument your application

Instrument your application to send custom metrics and APM traces through DogStatsD and the Datadog Trace Agent.
Download and import the [relevant libraries][6] to send data. To learn more, check out the [DogSatsD documentation][7] and [APM documentation][8].

| Variable | Description|
| -- | -- |
| `DD_APM_INSTRUMENTATION_ENABLED` | Use this option to automatically instrument your application, without any additional installation or configuration steps. See [Single Step APM Instrumentation](https://docs.datadoghq.com/tracing/trace_collection/single-step-apm/?tab=linuxhostorvm). |
| `DD_WAIT_TRACE_AGENT` | Use this option to delay the startup of the application until the Trace Agent is ready. This option is especially useful for Golang apps. |

### Log collection

**Enable log collection**

To collect logs from your application in CloudFoundry, the Agent contained in the buildpack needs to be activated with log collection enabled.

```yaml
env:
  DD_API_KEY: <DATADOG_API_KEY>
  DD_LOGS_ENABLED: true
  # Disable the Agent core checks to disable system metrics collection
  DD_ENABLE_CHECKS: false
  # Redirect Container Stdout/Stderr to a local port so the agent can collect the logs
  STD_LOG_COLLECTION_PORT: <PORT>
  # Configure the agent to collect logs from the wanted port and set the value for source and service
  LOGS_CONFIG: '[{"type":"tcp","port":"<PORT>","source":"<SOURCE>","service":"<SERVICE>"}]'
```

**Configure log collection**

The following environment variables are used to configure log collection.

| Variable | Description|
| -- | -- |
| `STD_LOG_COLLECTION_PORT` |  Must be used when collecting logs from `stdout`/`stderr`. It redirects the `stdout`/`stderr` stream to the corresponding local port value. |
| `LOGS_CONFIG` |  Use this option to configure the Agent to listen to a local TCP port and set the value for the `service` and `source` parameters. The port specified in the configuration must be the same as specified in the environment variable `STD_LOG_COLLECTION_PORT`. |
| `SUPPRESS_DD_AGENT_OUTPUT` | Use this option to see the Datadog agent, Trace agent and DogStatsD logs in the `cf logs`  output. |
| `DD_SPARSE_APP_LOGS` | Use this option to avoid losing log lines when app sparsely writes to STDOUT. |


**Example**

An `app01` Java application is running in Cloud Foundry. The following configuration redirects the container `stdout`/`stderr` to the local port 10514. It then configures the Agent to collect logs from that port while setting the proper value for `service` and `source`:

```yaml
env:
  DD_API_KEY: <DATADOG_API_KEY>
  DD_LOGS_ENABLED: true
  DD_ENABLE_CHECKS: false
  STD_LOG_COLLECTION_PORT: 10514
  LOGS_CONFIG: '[{"type":"tcp","port":"10514","source":"java","service":"app01"}]'
```

### Unified Service Tagging

> This feature requires the Datadog Cluster Agent to be installed.
See [Datadog Cluster Agent BOSH Release](https://github.com/DataDog/datadog-cluster-agent-boshrelease).

Unified service tagging ties Datadog telemetry together using three reserved tags: `env`, `service`, and `version`. In Cloud Foundry, they are set through the application labels/annotations and `DD_ENV`, `DD_SERVICE` and `DD_VERSION` environment variables, as shown in the example below:

```yaml
 env:
    DD_ENV: <ENV_NAME>
    DD_SERVICE: <SERVICE_NAME>
    DD_VERSION: <VERSION>
  metadata:
    labels:
      tags.datadoghq.com/env: <ENV_NAME>
      tags.datadoghq.com/service: <SERVICE_NAME>
      tags.datadoghq.com/version: <VERSION>
```

The `tags.datadoghq.com` prefix is part of the Agent Autodiscovery notation as described in [Basic Agent Autodiscovery documentation](https://docs.datadoghq.com/getting_started/containers/autodiscovery).

You can find more information in the [Unified Service Tagging documentation](https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging).

### Application Metadata collection

> This feature requires both the Datadog Agent and the Datadog Cluster Agent to be installed.
See [Datadog Agent BOSH Release](https://github.com/DataDog/datadog-cluster-agent-boshrelease) and [Datadog Cluster Agent BOSH Release](https://github.com/DataDog/datadog-cluster-agent-boshrelease).

You can enable the collection of your application metadata (labels and annotations) as tags in your application logs, traces and metrics by setting the environment variable `DD_ENABLE_CAPI_METADATA_COLLECTION` to `true`.

__Note__: Enabling this feature might trigger a restart of the Datadog Agent when the application metadata are updated, depending on the `cloud_foundry_api.poll_interval` on the Datadog Cluster Agent. On average, it takes around 20 seconds to restart the agent.


## Docker

If you're running Docker on Cloud Foundry, review the [`docker` directory][9] to adapt this buildpack to use in a `dockerfile`.


[1]: https://docs.cloudfoundry.org/buildpacks/understand-buildpacks.html#supply-script
[2]: https://github.com/DataDog/datadog-cloudfoundry-buildpack/releases/latest/download/datadog-cloudfoundry-buildpack.zip
[3]: /DEVELOPMENT.md#building
[4]: https://docs.cloudfoundry.org/buildpacks/use-multiple-buildpacks.html
[5]: https://github.com/DataDog/datadog-agent/blob/master/docs/agent/config.md#environment-variables
[6]: https://docs.datadoghq.com/libraries/
[7]: https://docs.datadoghq.com/guides/DogStatsD/
[8]: https://docs.datadoghq.com/tracing/setup_overview/
[9]: docker/
