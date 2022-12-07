#!/bin/bash

# these must be sourced because otherwise they will be blocking

source "${DATADOG_DIR}/run-datadog.sh"
source "${DATADOG_DIR}/redirect-logs.sh"

# Run the Docker command
exec "$@"
