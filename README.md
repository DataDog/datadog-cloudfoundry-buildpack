# Datadog Cloud Foundry Buildpack

This is a [decorator buildpack](https://github.com/cf-platform-eng/meta-buildpack/blob/master/README.md#decorators) for Cloud Foundry. It will install a Datadog Dogstatsd binary on the container your app is running on. It uses the new Agent 6 build of Dogstatsd, which is very light weight and powerful. You should barely notice it running on your container.

## Use

### Install the [Meta Buildpack](https://github.com/cf-platform-eng/meta-buildpack#how-to-install-the-meta-buildpack)
First, you will have to [install the Meta Buildpack](https://github.com/cf-platform-eng/meta-buildpack#how-to-install-the-meta-buildpack). This enables apps to use decorator buildpacks. Follow the instructions to get the buildpack and upload it if you don't already have it.

### Upload the Datadog Cloud Foundry Buildpack
You can get it from the [releases page](https://github.com/DataDog/datadog-cloudfoundry-buildpack/releases) here, or you can just [download the latest version directly from us](https://cloudfoundry.datadoghq.com/datadog-cloudfoundry-buildpack/datadog-cloudfoundry-buildpack-latest.zip). After you download the zipfile, you will have to upload it to Cloud Foundry:

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

### Statsd Away!
You're all set up to use Dogstatsd. Import the relevant library and start sending data! To learn more, [check our our documentation](https://docs.datadoghq.com/guides/dogstatsd/).


## Building
To build this buildpack, simply edit the relevant files and run the `./build` script. If you want to upload it, run `./upload`.
