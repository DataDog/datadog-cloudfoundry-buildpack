# Datadog Cloud Foundry Buildpack

This is a [supply buildpack](https://docs.cloudfoundry.org/buildpacks/understand-buildpacks.html#supply-script) for Cloud Foundry. It will install the Datadog Agent in the container your app is running on, so that you can send Dogstatsd metrics, send traces for APM and get logs from your app. It contains the agent for both the linux and windows stacks.

## Use

### Upload the buildpack to CF
- Download the latest Datadog [build pack release](https://cloudfoundry.datadoghq.com/datadog-cloudfoundry-buildpack/datadog-cloudfoundry-buildpack-latest.zip) or [build it](#building). After you have the zipfile, you will have to upload it to Cloud Foundry environment.

- Create the buildpack in CF if it does not exist
    ```bash
    cf create-buildpack datadog-cloudfoundry-buildpack datadog-cloudfoundry-buildpack.zip 99 --enable
    ```
    or update it if it already exists
    ```bash
    cf update-buildpack datadog-cloudfoundry-buildpack -p datadog-cloudfoundry-buildpack.zip
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

**Additional steps for windows**

To get logs from your .NET Framework applications running on windows cells, follow these additional steps:
1. Create a `Procfile` at the root of your app containing the following line:
    ```
    web: run.cmd
    ```
2. Create a file named `run.cmd` at the root of your application. This file contains the command to startup your application
    ```batch
    .cloudfoundry\hwc.exe 2>&1 | "C:\Users\vcap\app\datadog\datadog agent\embedded2\python.exe" "C:\Users\vcap\app\datadog\scripts\redirect_logs.py"
    ```
    This command starts the usual `hwc` buildpack, and redirects its output to a script that forwards it to the agent, so that your app logs appear in Datadog.

**Example**:

An `app01` Java application is running in Cloud Foundry. The following configuration redirects the container `stdout`/`stderr` to the local port 10514. It then configures the Agent to collect logs from that port while setting the proper value for `service` and `source`:

```
# Redirect Stdout/Stderr to port 10514
cf set-env $YOUR_APP_NAME STD_LOG_COLLECTION_PORT 10514
# Configure the agent to listen to that port
cf set-env $YOUR_APP_NAME LOGS_CONFIG '[{"type":"tcp","port":"10514","source":"java","service":"app01"}]'
```

#### .NET Traces

The buildpack also includes the [.NET Tracer](https://docs.datadoghq.com/tracing/setup/dotnet/?tab=netframeworkonwindows) for the .NET Framework on windows cells. To start instrumenting your app, register the directory containing the DLLs in your app.
To do so, add the path `C:\Users\vcap\app\datadog\dotNetTracer` in the [`probing`](https://docs.microsoft.com/en-us/dotnet/framework/configure-apps/file-schema/runtime/probing-element) element in your `web.config` file.

**example**:
```xml
<runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
        <probing privatePath="C:\Users\vcap\app\datadog\dotNetTracer" />
    </assemblyBinding>
</runtime>
```

Alternatively, you can install the [Datadog.Trace.ClrProfiler.Managed Nuget package](https://www.nuget.org/packages/Datadog.Trace.ClrProfiler.Managed) in your app before pushing it to CloudFoundry.

Finally, set the following environment variables in your application:
```
cf set-env $YOUR_APP_NAME COR_ENABLE_PROFILING 1
cf set-env $YOUR_APP_NAME COR_PROFILER {846F5F1C-F9AE-4B07-969E-05C26BC060D8}
cf set-env $YOUR_APP_NAME COR_PROFILER_PATH C:\Users\vcap\app\datadog\dotNetTracer\Datadog.Trace.ClrProfiler.Native.dll
```

### DogStatsD Away!
You're all set up to use DogStatsD. Import the relevant library and start sending data! To learn more, [check our our documentation](https://docs.datadoghq.com/guides/DogStatsD/). Additionally, we have [a list of DogStatsD libraries](https://docs.datadoghq.com/libraries/) you can check out to find one that's compatible with your application.


## Building
Run the following command from the root of the repository to build the buildpack with the latest agent:
```bash
./build
```

If you want to build for a specific version of the agent, specify the VERSION environment variable.
```bash
VERSION=<AGENT_VERSION> REFRESH_ASSETS=1 ./build
```

This produces a `datadog-cloudfoundry-buildpack.zip` file at the root of the repository that you can use directly with the CF CLI, or to build the [datadog-application-monitoring tile](https://github.com/DataDog/pcf-datadog-application-monitoring).

## Docker

If you're running docker on Cloud Foundry, you can look at [the docker directory](docker/) to see how to adapt this buildpack to use in a dockerfile
