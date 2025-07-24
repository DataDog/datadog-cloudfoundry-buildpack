# cf-go-sample-app
Sample go application for CloudFoundry that sends metrics, logs, and traces to Datadog.

### How to push the app

1. Edit the `manifest.yml` with your DD credentials
3. Run `cf push --var DD_API_KEY=<API_KEY> --var ENV=<ENV_NAME>`

### How to run locally 

1. Build the app: `./build.sh`. This will create a `main` binary. 
2. Run the app with `./main`