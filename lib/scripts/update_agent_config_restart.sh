#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# This script is called by the node agent to expose CAPI metadata and DCA tags to the container agents
# It sets the DD_NODE_AGENT_TAGS environment variable with these new tags
# see: https://github.com/DataDog/datadog-agent/blob/7.40.x/pkg/cloudfoundry/containertagger/container_tagger.go#L131


DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"

source "${DATADOG_DIR}/scripts/common.sh"

export DD_NODE_AGENT_TAGS_NEW=${DD_NODE_AGENT_TAGS}

# correct way to export / source the .datadog_env file so that every variable is parsed
python "${DATADOG_DIR}/scripts/parse_env_vars.py" "${DATADOG_DIR}/.datadog_env" "${DATADOG_DIR}/.new_datadog_env"
source "${DATADOG_DIR}/.new_datadog_env"

export DD_NODE_AGENT_TAGS=${DD_NODE_AGENT_TAGS_NEW}
export DD_TAGS=$(LEGACY_TAGS_FORMAT=true python "${DATADOG_DIR}/scripts/get_tags.py" node-agent-tags)

# the agent cloud_foundry_container workloadmeta collector reads from this file
# See: https://github.com/DataDog/datadog-agent/blob/main/pkg/workloadmeta/collectors/internal/cloudfoundry/cf_container/cloudfoundry_container.go#L24
echo "$DD_TAGS" | awk '{ printf "%s", $0 }' >  "${DATADOG_DIR}/node_agent_tags.txt"

# for debugging purposes
printenv > "${DATADOG_DIR}/.sourced_datadog_env"

# import helper functions
source "${DATADOG_DIR}/scripts/utils.sh"

stop_datadog() {
  pushd "${DATADOG_DIR}"
    # first try to stop the agent so we don't lose data and then force it
    if [ -f run/agent.pid ]; then
      log_message $0 "Stopping agent process, pid: $(cat run/agent.pid)"
      (./agent stop --cfgpath dist/) || true
      agent_commad="./agent run --cfgpath dist/ --pidfile run/agent.pid"
      find_pid_kill_and_wait "$agent_commad" || true
      kill_and_wait "${DATADOG_DIR}/run/agent.pid" 5
      rm -f "run/agent.pid"
    fi

    if [ -f run/trace-agent.pid ]; then
      log_message $0 "Stopping trace agent process, pid: $(cat run/trace-agent.pid)"
      trace_agent_command="./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid"
      kill_and_wait "${DATADOG_DIR}/run/trace-agent.pid" 5 1
      find_pid_kill_and_wait "$trace_agent_command" "${DATADOG_DIR}/run/trace-agent.pid"
      rm -f "run/trace-agent.pid"
    fi

    if [ -f run/dogstatsd.pid ]; then
      log_message $0 "Stopping dogstatsd agent process, pid: $(cat run/dogstatsd.pid)"
      dogstatsd_command="./dogstatsd start --cfgpath dist/"
      kill_and_wait "${DATADOG_DIR}/run/dogstatsd.pid" 5 1
      find_pid_kill_and_wait "$dogstatsd_command" "${DATADOG_DIR}/run/dogstatsd.pid"
      rm -f "run/dogstatsd.pid"
    fi
  popd
}

start_datadog() {
  pushd "${DATADOG_DIR}"

    export DD_LOG_FILE="${DATADOG_DIR}/dogstatsd.log"
    export DD_API_KEY
    export DD_DD_URL
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-false}"
    export DOCKER_DD_AGENT=yes
    export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
    export LOGS_CONFIG
    export DD_API_KEY

    if [ -a ./agent ] && { [ "$DD_LOGS_ENABLED" = "true" ] || [ "$DD_ENABLE_CHECKS" = "true" ]; }; then
      if [ "$DD_LOGS_ENABLED" = "true" -a "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
        log_message $0 "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=agent.log
        export DD_IOT_HOST=false

        log_message $0 "Starting Datadog agent"
        python scripts/create_logs_config.py

        if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
          ./agent run --cfgpath dist/ --pidfile run/agent.pid > /dev/null 2>&1 &
        else
          ./agent run --cfgpath dist/ --pidfile run/agent.pid &
        fi
      fi
    else
      log_message $0 "Starting dogstatsd agent"
      export DD_LOG_FILE=dogstatsd.log
      if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
        ./dogstatsd start --cfgpath dist/ > /dev/null 2>&1 &
      else
        ./dogstatsd start --cfgpath dist/ &
      fi
      echo $! > run/dogstatsd.pid
    fi
    log_message $0 "Starting trace agent"
    if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
      ./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid > /dev/null 2>&1 &
    else
      ./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid &
    fi
  popd
}


main() {
    # After the tags are parsed and added to DD_TAGS, we need to restart the agent for the changes to take effect
    log_message $0 "stop datadog to refresh tags"
    stop_datadog

    # setup the redirection from stdout/stderr to the logs-agent.
    if [ "$DD_LOGS_ENABLED" = "true" ]; then
        if [ "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
            echo "Log endpoint not valid, not starting log redirection"
        else
            if [ -z "$LOGS_CONFIG" ]; then
                echo "can't collect logs, LOGS_CONFIG is not set"
                else
                echo "collect all logs for config $LOGS_CONFIG"
                if [ -n "$STD_LOG_COLLECTION_PORT" ]; then
                    echo "forward all logs from stdout/stderr to agent port $STD_LOG_COLLECTION_PORT"
                    exec &> >(tee >(redirect))
                fi
            fi
        fi
    fi
    log_message $0 "start datadog to refresh tags"
    start_datadog
}

main "$@"
