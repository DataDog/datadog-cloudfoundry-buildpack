# Datadog Cloud Foundry Buildpack

This is a [decorator buildpack](https://github.com/cf-platform-eng/meta-buildpack/blob/master/README.md#decorators) for Cloud Foundry. It will install a Datadog DogStatsD binary in the container your app is running on. This only contains the DogStatsd components of Datadog Agent, which has limited overhead.

## Use

### Install the [Meta Buildpack](https://github.com/cf-platform-eng/meta-buildpack#how-to-install-the-meta-buildpack)
First, you will have to [install the Meta Buildpack](https://github.com/cf-platform-eng/meta-buildpack#how-to-install-the-meta-buildpack). This enables apps to use decorator buildpacks. Follow the instructions to get the buildpack and upload it if you don't already have it.

### Upload the Datadog Cloud Foundry Buildpack
Download the latest Datadog [build pack release](https://cloudfoundry.datadoghq.com/datadog-cloudfoundry-buildpack/datadog-cloudfoundry-buildpack-latest.zip). After you download the zipfile, you will have to upload it to Cloud Foundry environment.

```shell
cf create-buildpack datadog-cloudfoundry-buildpack datadog-cloudfoundry-buildpack.zip 99 --enable
```

### Configuration

#### Metric Collection

**Set an API Key in your environment to enable the buildpack**:

```shell
# set the environment variable
cf set-env $YOUR_APP_NAME DD_API_KEY $YOUR_DATADOG_API_KEY
# restage the application to get it to pick up the new environment variable and use the buildpack
cf restage $YOUR_APP_NAME
```

#### Log Collection

**Enable log collection**:

To start collecting logs from your application in CloudFoundry, the Agent contained in the buildpack needs to be activated and log collection enabled.

```
cf set-env $YOUR_APP_NAME RUN_AGENT true
cf set-env $YOUR_APP_NAME DD_LOGS_ENABLED true
# Disable the Agent core checks to disable system metrics collection
cf set-env $YOUR_APP_NAME DD_ENABLE_CHECKS false
# Redirect Container Stdout/Stderr to a local port so the agent can collect the logs
cf set-env $YOUR_APP_NAME STD_LOG_COLLECTION_PORT <PORT>
# Configure the agent to collect logs from the wanted port and set the value for source and service
cf set-env $YOUR_APP_NAME LOGS_CONFIG '[{"type":"tcp","port":"<PORT>","source":"<SOURCE>","service":"<SERVICE>"}]'
# restage the application to get it to pick up the new environment variable and use the buildpack
cf restage $YOUR_APP_NAME
```

**Configure log collection**:

The following parameters can be used to configure log collection:

- `STD_LOG_COLLECTION_PORT`: Must be used when collecting logs from `stdout`/`stderr`. It redirects the `stdout`/`stderr` stream to the corresponding local port value.
- `LOGS_CONFIG`: Use this option to configure the agent to listen to a local TCP port and set the value for the `service` and `source` parameters.

**Example**:

An `app01` Java application is running in Cloud Foundry. The following configuration redirects the container `stdout`/`stderr` to the local port 10514. It then configures the Agent to collect logs from that port while setting the proper value for `service` and `source`:

```
# Redirect Stdout/Stderr to port 10514
cf set-env $YOUR_APP_NAME STD_LOG_COLLECTION_PORT 10514
# Configure the agent to listen to that port
cf set-env $YOUR_APP_NAME LOGS_CONFIG '[{"type":"tcp","port":"10514","source":"java","service":"app01"}]'
```

### DogStatsD Away!
You're all set up to use DogStatsD. Import the relevant library and start sending data! To learn more, [check our our documentation](https://docs.datadoghq.com/guides/DogStatsD/). Additionally, we have [a list of DogStatsD libraries](https://docs.datadoghq.com/libraries/) you can check out to find one that's compatible with your application.


## Building
To build this buildpack, simply edit the relevant files and run the `./build` script. If you want to upload it, run `./upload`.

## Docker

If you're running docker on Cloud Foundry, you can look at [the docker directory](docker/) to see how to adapt this buildpack to use in a dockerfile
