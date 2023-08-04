#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
LOCK="${DATADOG_DIR}/update_agent_config.lock"

# source updated PATH
. "$DATADOG_DIR/.global_env"

# import utils function such as log_message
release_lock() {
    log_info "releasing lock '${LOCK}'"
    rmdir "${LOCK}"
}

write_tags_to_file() {
    export DD_TAGS=$(ruby "${DATADOG_DIR}"/scripts/get_tags.rb)

    export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
    export LOGS_CONFIG

    log_info "Updating node_agent_tags.txt"
    ruby "${DATADOG_DIR}/scripts/update_tags.rb"

    # update datadog config
    ruby "${DATADOG_DIR}/scripts/update_datadog_config.rb"

    if [ "${DD_ENABLE_CAPI_METADATA_COLLECTION}" = "true" ]; then
        # update logs configs
        if [ -n "${LOGS_CONFIG}" ]; then
            mkdir -p "${LOGS_CONFIG_DIR}"
            log_info "Updating logs config"
            ruby "${DATADOG_DIR}/scripts/create_logs_config.rb"
        fi
    fi

    # log DD_TAGS and DD_NODE_AGENT_TAGS values
    log_debug "node_agent_tags.txt=$(cat "${DATADOG_DIR}"/node_agent_tags.txt)"
    log_debug "(AFTER)DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS}"
    log_debug "DD_TAGS=${DD_TAGS}"
}

main() {
    # source relevant DD tags
    while ! [ -f "${DATADOG_DIR}/.setup_completed" ]; do
        echo "Datadog setup is not completed, waiting ..."
        sleep 1
    done

    . "${DATADOG_DIR}/scripts/utils.sh"
    safe_source "${DATADOG_DIR}/.datadog_env"

    log_info "starting update_agent_config script"
    log_debug "(BEFORE)DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS}"

    # try to create the LOCK
    while ! mkdir "${LOCK}" 2>/dev/null; do
        log_info "cannot acquire lock, script is already running"
        sleep 1
    done

    log_info "acquired lock '${LOCK}'"

    # ensures the lock is released on exit
    trap release_lock INT TERM EXIT

    # wait for the buildpack scripts to finish
    log_info "starting check_datadog script"

    while ! [ -f "${DATADOG_DIR}/scripts/check_datadog.sh" ]; do
        log_info "check_datadog.sh script not found, waiting..."
        sleep 2
    done

    timeout 300s "${DATADOG_DIR}/scripts/check_datadog.sh"
    exit_code=$?

    # verify that check_datadog exited successfully
    if [ ${exit_code} -ne  0 ]; then
        log_error "could not find agent, aborting update script!"
        exit ${exit_code}
    fi

    log_info "finished check_datadog script"

    # the agent cloud_foundry_container workloadmeta collector reads from this file
    # See: https://github.com/DataDog/datadog-agent/blob/main/pkg/workloadmeta/collectors/internal/cloudfoundry/cf_container/cloudfoundry_container.go#L24
    # update node_agent_tags.txt
    write_tags_to_file

    # finishing up
    log_info "exporting .sourced_datadog_env file"
    dd_export_env "${DATADOG_DIR}/.sourced_datadog_env"

    if [ "${DD_ENABLE_CAPI_METADATA_COLLECTION}" != "true" ]; then
        log_info "update script aborted. set DD_ENABLE_CAPI_METADATA_COLLECTION to true to enable metadata tags collection"
        exit 0
    fi

    # mark to the monit_datadog function in run-datadog.sh that the script is finished
    log_info "creating tags_updated file"
    touch "${DATADOG_DIR}/tags_updated"

    log_info "finished update_agent_config script"
}

# for debugging purposes
main "$@" 2>&1 | tee -a "${DATADOG_DIR}/update_agent_script.log"
