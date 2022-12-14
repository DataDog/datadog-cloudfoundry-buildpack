#!/bin/sh

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
LOCKFILE="${DATADOG_DIR}/update.lock"

. "${DATADOG_DIR}/scripts/common.sh"

release_lock() {
    log_message "$0" "$$" "Releasing LOCKFILE"
    rmdir "$LOCKFILE"
}

main() {
    log_message "$0" "$$" "Starting Update Script"

    # try to create the LOCKFILE
    while ! mkdir "$LOCKFILE" 2>/dev/null; do
        log_message "$0" "$$" "Script is already running"
        sleep 1
    done

    # ensures the lock is released on exit
    trap release_lock INT TERM EXIT

    log_message "$0" "$$" "Starting to wait for agent process to start"

    # wait for the buildpack scripts to finish
    timeout 300s "${DATADOG_DIR}/scripts/check_datadog.sh"

    # TODO: check for dogstatsd as well
    if ! [ -f "${DATADOG_DIR}/run/agent.pid" ]; then
        log_message "$0" "$$" "Could not find agent, aborting update script!"
        exit 1
    fi

    if [ -f "${DATADOG_DIR}/run/agent.pid" ]; then
        if ! [ -f "${DATADOG_DIR}/dist/auth_token" ]; then
          log_message "$0" "$$" "Could not find agent token, aborting update script!"
          exit 2
        fi
    fi

    export DD_TAGS=$(LEGACY_TAGS_FORMAT=true python "${DATADOG_DIR}/scripts/get_tags.py" node-agent-tags)

    log_message "$0" "$$" "DD_TAGS=${DD_TAGS}"
    # the agent cloud_foundry_container workloadmeta collector reads from this file
    # See: https://github.com/DataDog/datadog-agent/blob/main/pkg/workloadmeta/collectors/internal/cloudfoundry/cf_container/cloudfoundry_container.go#L24
    log_message "$0" "$$" "Writing DD_TAGS to node_agent_tags.txt"
    echo "${DD_TAGS}" | awk '{ printf "%s", $0 }' >  "${DATADOG_DIR}/node_agent_tags.txt"
    log_message "$0" "$$" "node_agent_tags.txt=$(cat ${DATADOG_DIR}/node_agent_tags.txt)"
    

    echo "running ruby script"
    # /usr/bin/env ruby ${DATADOG_DIR}/scripts/update_yaml_config.rb

    log_message "$0" "$$" "DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS}"
  
    /bin/bash "${DATADOG_DIR}/scripts/update_agent_config_restart.sh"

    log_message "$0" "$$" "Finished Update Script"

    touch $DATADOG_DIR/tags_updated
}
# for debugging purposes
main "$@" 2>&1 | tee /dev/fd/1 -a "$DEBUG_FILE"
