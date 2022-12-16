#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.



DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
LOCK="${DATADOG_DIR}/update.lock"

# import utils function such as log_message
. "${DATADOG_DIR}/scripts/utils.sh"

release_lock() {
    log_message "$0" "$$" "releasing LOCK ${LOCK}"
    rmdir "${LOCK}"
}

main() {
    log_message "$0" "$$" "starting update_agent_config script"
    log_message "$0" "$$" "(BEFORE)DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS}"

    # try to create the LOCK
    while ! mkdir "${LOCK}" 2>/dev/null; do
        log_message "$0" "$$" "cannot acquire lock, script is already running"
        sleep 1
    done

    log_message "$0" "$$" "acquired LOCK ${LOCK}"
   
    # ensures the lock is released on exit
    trap release_lock INT TERM EXIT

    # wait for the buildpack scripts to finish
    log_message "$0" "$$" "starting check_datadog script"
    timeout 300s "${DATADOG_DIR}/scripts/check_datadog.sh" 
    exit_code=$?
    log_message "$0" "$$" "finished check_datadog script"

    # verify that check_datadog didn't end because of the timeout
    if [ ${exit_code} -ne  0 ]; then
        log_message "$0" "$$" "could not find agent, aborting update script!"
        exit ${exit_code}
    fi

    # source relevant DD tags
    . "${DATADOG_DIR}/.datadog_env"

    # combine DD_TAGS and DD_NODE_AGENT_TAGS into DD_TAGS
    export DD_TAGS="$(LEGACY_TAGS_FORMAT=true python "${DATADOG_DIR}/scripts/get_tags.py" node-agent-tags)"
    export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
    export LOGS_CONFIG

    # update logs configs with the new tags
    log_message "$0" "$$" "running create_logs_config ruby script"
    ruby "${DATADOG_DIR}/scripts/create_logs_config.rb" 2>&1 | tee -a "$DATADOG_DIR/ruby_script.3.log"

    # the agent cloud_foundry_container workloadmeta collector reads from this file
    # See: https://github.com/DataDog/datadog-agent/blob/main/pkg/workloadmeta/collectors/internal/cloudfoundry/cf_container/cloudfoundry_container.go#L24
    log_message "$0" "$$" "Writing DD_TAGS to node_agent_tags.txt"
    echo "${DD_TAGS}" | awk '{ printf "%s", $0 }' >  "${DATADOG_DIR}/node_agent_tags.txt"
    
    # log DD_TAGS and DD_NODE_AGENT_TAGS values
    log_message "$0" "$$" "node_agent_tags.txt=$(cat ${DATADOG_DIR}/node_agent_tags.txt)"
    log_message "$0" "$$" "(AFTER)DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS}"

    
    # finishing up
    log_message "$0" "$$" "exporting .sourced_datadog_env file"
    printenv > "${DATADOG_DIR}/.sourced_datadog_env"

    # mark to the monit_datadog function in run-datadog.sh that the script is finished
    log_message "$0" "$$" "creating tags_updated file"
    touch "${DATADOG_DIR}/tags_updated"

    log_message "$0" "$$" "finished update_agent_config script"
}

# for debugging purposes
main "$@" 2>&1 | tee -a "$DEBUG_FILE"
