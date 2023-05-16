#!/usr/bin/env bash

DATADOG_DIR="/home/vcap/app/.datadog"

main() {
    echo "Running entrypoint.sh script"
    source "${DATADOG_DIR}/00-test-endpoint.sh"
    source "${DATADOG_DIR}/01-run-datadog.sh"
    source "${DATADOG_DIR}/02-redirect-logs.sh"
}

main "$@" 2>&1 | tee -a "${DATADOG_DIR}/entrypoint.log"

