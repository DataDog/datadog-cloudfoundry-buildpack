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
You will need to set an API Key in your environment to enable the buildpack:

```shell
# set the environment variable
cf set-env $YOUR_APP_NAME DD_API_KEY $YOUR_DATADOG_API_KEY
# restage the application to get it to pick up the new environment variable and use the buildpack
cf restage $YOUR_APP_NAME
```

You can also enable log collection.
By default, all logs from stdout and stderr are collected and forwarded to the agent by TCP on port 10514.
You can disable stdout/stderr log collection if you just want to collect your application logs, you'll need to manage log-TCP-forwarding on your own.
```shell
# set the environment variables
cf set-env $YOUR_APP_NAME DD_API_KEY $YOUR_DATADOG_API_KEY
cf set-env $YOUR_APP_NAME RUN_PUPPY true
cf set-env $YOUR_APP_NAME DD_LOGS_ENABLED true
# override the TCP port
cf set-env $YOUR_APP_NAME DD_LOGS_CONFIG_TCP_FORWARD_PORT 10514
# disable log collection on stdout/stderr
cf set-env $YOUR_APP_NAME DISABLE_STD_LOG_COLLECTION true
# restage the application to get it to pick up the new environment variable and use the buildpack
cf restage $YOUR_APP_NAME
```

### DogStatsD Away!
You're all set up to use DogStatsD. Import the relevant library and start sending data! To learn more, [check our our documentation](https://docs.datadoghq.com/guides/DogStatsD/). Additionally, we have [a list of DogStatsD libraries](https://docs.datadoghq.com/libraries/) you can check out to find one that's compatible with your application.


## Building
To build this buildpack, simply edit the relevant files and run the `./build` script. If you want to upload it, run `./upload`.
