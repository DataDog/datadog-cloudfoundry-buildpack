#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# This script is called by the node agent to expose CAPI metadata and DCA tags to the container agents
# It sets the DD_NODE_AGENT_TAGS environment variable with these new tags
# see: https://github.com/DataDog/datadog-agent/blob/7.40.x/pkg/cloudfoundry/containertagger/container_tagger.go#L131

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"

# import log_message and DATADOG_DIR
source "${DATADOG_DIR}/scripts/common.sh"

export DD_NODE_AGENT_TAGS_NEW=${DD_NODE_AGENT_TAGS}

# correct way to export / source the .datadog_env file so that every variable is parsed and sanitized
source "${DATADOG_DIR}/.datadog_env"

export DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS_NEW}
export DD_TAGS=$(LEGACY_TAGS_FORMAT=true python "${DATADOG_DIR}/scripts/get_tags.py" node-agent-tags)
export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
export LOGS_CONFIG

echo "running ruby script"
ruby $DATADOG_DIR/scripts/create_logs_config.rb 2>&1 | tee -a "$DATADOG_DIR/ruby_script.2.log"
# ruby "${DATADOG_DIR}/scripts/update_yaml_config.rb" 2>&1 | tee -a "$DATADOG_DIR/ruby_script.2.log"

echo "LOGS_CONFIG: $(cat ${DATADOG_DIR}/dist/conf.d/logs.d/logs.yaml)"

# the agent cloud_foundry_container workloadmeta collector reads from this file
# See: https://github.com/DataDog/datadog-agent/blob/main/pkg/workloadmeta/collectors/internal/cloudfoundry/cf_container/cloudfoundry_container.go#L24
echo "$DD_TAGS" | awk '{ printf "%s", $0 }' >  "${DATADOG_DIR}/node_agent_tags.txt"

# for debugging purposes
printenv > "${DATADOG_DIR}/.sourced_datadog_env"




# import helper functions
source "${DATADOG_DIR}/scripts/utils.sh"