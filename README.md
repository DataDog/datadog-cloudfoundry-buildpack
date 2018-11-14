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

#### Log Collection (Beta - No official release yet)

To start collecting logs from your application in CloudFoundry, use the following configuration:

```
# activate the agent
cf set-env $YOUR_APP_NAME RUN_AGENT true
# enable log collection
cf set-env $YOUR_APP_NAME DD_LOGS_ENABLED true
# add a custom config
cf set-env $YOUR_APP_NAME LOGS_CONFIG '[{"type":"tcp","port":"<PORT>","source":"<SOURCE>","service":"<SERVICE>"}]'
# disable the Agent core checks to disable system metrics collection
cf set-env $YOUR_APP_NAME DD_ENABLE_CHECKS false
# restage the application to get it to pick up the new environment variable and use the buildpack
cf restage $YOUR_APP_NAME
```

Collect logs from stdout/stderr:

```
# stdout/stderr forwarding only
cf set-env $YOUR_APP_NAME STD_LOG_COLLECTION_PORT 10514
cf set-env $YOUR_APP_NAME LOGS_CONFIG '[{"type":"tcp","port":"<PORT>","source":"<SOURCE>","service":"<SERVICE>"}]'
# stdout/stderr forwarding with additional config
cf set-env $YOUR_APP_NAME STD_LOG_COLLECTION_PORT 10514
cf set-env $YOUR_APP_NAME LOGS_CONFIG '[{"type":"tcp","port":"10514","source":"<SOURCE>","service":"<SERVICE>"},{"type":"tcp","port":"<PORT>","source":"<SOURCE>","service":"<SERVICE>"}]'
```

### DogStatsD Away!
You're all set up to use DogStatsD. Import the relevant library and start sending data! To learn more, [check our our documentation](https://docs.datadoghq.com/guides/DogStatsD/). Additionally, we have [a list of DogStatsD libraries](https://docs.datadoghq.com/libraries/) you can check out to find one that's compatible with your application.


## Building
To build this buildpack, simply edit the relevant files and run the `./build` script. If you want to upload it, run `./upload`.
