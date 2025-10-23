# A sample Cloud Foundry App in Java

This App is an example of how to use the [Datadog Cloud Foundry Buildpack](https://github.com/datadog/datadog-cloudfoundry-buildpack).

## Prerequisite

This project is meant to run on Java 17. If you don't have JDK 17 installed, 
you can install it with the command: 

``` bash
brew install openjdk@17
```

Also make sure to install Maven, as this is the tool used to build the 
project. To install Maven you can run the command:

``` bash
brew install maven
```

## How to build and push

1. To run this app in your Cloud Foundry environment, first you need to build the app. Run `./build.sh`.
2. Update the `manifest.yml` file with any other extra configuration options.
3. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`, substituting `<API_KEY>` with your Datadog API key value.