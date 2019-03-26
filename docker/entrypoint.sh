#!/bin/bash

# these must be sourced because otherwise they can be blocking
source $DATADOG_DIR/run-datadog.sh
source $DATADOG_DIR/redirect-logs.sh

exec "$@"
