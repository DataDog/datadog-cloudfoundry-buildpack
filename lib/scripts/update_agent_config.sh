#!/bin/sh

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
DEBUG_FILE="${DATADOG_DIR}/update_agent_config_out.log"

main() {
    # wait for the buildpack scripts to finish
    echo "Starting to wait for agent process to start"
    timeout 120s "${DATADOG_DIR}/scripts/check_datadog.sh"

    echo "$DD_NODE_AGENT_TAGS"

    /bin/bash "${DATADOG_DIR}/scripts/update_agent_config_restart.sh"
}
# for debugging purposes
main "$@" >> "$DEBUG_FILE" 2>&1
