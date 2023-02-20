# Development

This repository contains the buildpack packaging for the Datadog Agent. See more information about buildpack development [here](https://docs.cloudfoundry.org/buildpacks/developing-buildpacks.html).

The main logic can be found in the shell scripts under the `lib` directory.

## Building

To execute the `scripts/build.sh` script, `dpkg` needs to be installed.
On macOS, `brew install dpkg`.

Run the following command from the root of the repository to build the buildpack with the latest agent:
```bash
REFRESH_ASSETS=1 ./scripts/build.sh
```

If you want to build for a specific version of the agent, specify the VERSION environment variable.
```bash
VERSION=<AGENT_VERSION> REFRESH_ASSETS=1 ./scripts/build.sh
```

This produces a `datadog-cloudfoundry-buildpack.zip` file at the root of the repository that you can use directly with the CF CLI, or to build the [datadog-application-monitoring tile](https://github.com/DataDog/datadog-application-monitoring-pivotal-tile).
