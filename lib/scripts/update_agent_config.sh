#!/bin/sh

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
DEBUG_FILE="/home/vcap/app/.datadog/update_agent_config_out.log"

main() {
    # wait for the buildpack scripts to finish
    echo "Starting to wait for agent process to start"
    timeout 120s "${DATADOG_DIR}/scripts/check_datadog.sh"

    echo "$DD_NODE_AGENT_TAGS"

    /bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
}
# for debugging purposes
main "$@" >> "$DEBUG_FILE" 2>&1
