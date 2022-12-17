#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

source "${DATADOG_DIR}/scripts/utils.sh"

check_datadog() {
  while true; do
    log_message "$0" "$$" "Waiting for agent or dogstatsd process to start"
    if check_if_running "${AGENT_PIDFILE}" "${AGENT_CMD}"; then
      log_message "$0" "$$" "found agent process: $(cat "${AGENT_PIDFILE}")"
      if [ -f "${DATADOG_DIR}/dist/auth_token" ]; then
        log_message "$0" "$$" "found agent token"
        break
      else 
        log_message "$0" "$$" "agent token not found"
      fi
    fi

    if check_if_running "${DOGSTATSD_PIDFILE}" "${DOGSTATSD_CMD}"; then
      log_message "$0" "$$" "found dogstatsd process: $(cat "${DOGSTATSD_PIDFILE}")"
      break
    fi
    sleep 1
  done
}

main() {
    check_datadog
}

main "$@"