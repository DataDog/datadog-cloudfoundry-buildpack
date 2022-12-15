#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

source "${DATADOG_DIR}/scripts/common.sh"

check_datadog() {
  while true; do
    log_message "$0" "$$" "Waiting for agent or dogstatsd process to start"
    if kill -0 $(cat "${DATADOG_DIR}/run/agent.pid"); then
        log_message "$0" "$$" "Found agent process"
        if [ -f "${DATADOG_DIR}/dist/auth_token" ]; then
          log_message "$0" "$$" "Found agent token"
          break
        else 
          log_message "$0" "$$" "Agent token not found"
        fi
    fi

    if kill -0 $(cat "${DATADOG_DIR}/run/dogstatsd.pid"); then
        log_message "$0" "$$" "Found dogstatsd process"
        break
    fi
    sleep 1
  done
  sleep 5 # TODO: use agent status?
}

main() {
    check_datadog
}

main "$@"