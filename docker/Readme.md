# Docker in PCF

If you're using docker in PCF, you can't use the buildpack. This and the accompinying dockerfile will provide a guide to adding something very similar to this buildpack to your docker images.

# Dockerfile

The dockerfile contains both the datadog assets as well as a small flask app, and shows you how to set up an entrypoint file to start all of these things
