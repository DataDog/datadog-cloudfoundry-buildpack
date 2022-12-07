#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

check_datadog() {
  while true; do
    echo "Waiting for agent or dogstatsd process to start"
    if [ -f "${DATADOG_DIR}/run/agent.pid" ]; then
        echo "Found agent process"
        if [ -f "${DATADOG_DIR}/dist/auth_token" ]; then
          echo "Found agent token"
          break
        else 
          echo "Agent token not found"
        fi
    fi

    if [ -f "${DATADOG_DIR}/run/dogstatsd.pid" ]; then
        echo "Found dogstatsd process"
        break
    fi
    sleep 1
  done
}

main() {
    check_datadog
}

main "$@"