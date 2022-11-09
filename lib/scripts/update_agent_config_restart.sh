#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# This script is called by the node agent to expose CAPI metadata and DCA tags to the container agents
# It sets the DD_NODE_AGENT_TAGS environment variable with these new tags
# see: https://github.com/DataDog/datadog-agent/blob/7.40.x/pkg/cloudfoundry/containertagger/container_tagger.go#L131


DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"

# correct way to export / source the .datadog_env file so that every variable is parsed
export $(grep -v '^#' $DATADOG_DIR/.datadog_env | xargs)
export DD_TAGS=$(LEGACY_TAGS_FORMAT=true python $DATADOG_DIR/scripts/get_tags.py node-agent-tags)

# the agent cloud_foundry_container workloadmeta collector reads from this file
# See: https://github.com/DataDog/datadog-agent/blob/main/pkg/workloadmeta/collectors/internal/cloudfoundry/cf_container/cloudfoundry_container.go#L24
echo "$DD_TAGS" | awk '{ printf "%s", $0 }' > "$DATADOG_DIR/node_agent_tags.txt"

# for debugging purposes
printenv > /home/vcap/app/.datadog/.sourced_datadog_env

# import helper functions
source "$DATADOG_DIR/scripts/utils.sh"

stop_datadog() {

  # first try to stop the agent so we don't lose data and then force it
  if [ -f "$DATADOG_DIR/run/agent.pid" ]; then
    echo "Stopping agent process, pid: $(cat $DATADOG_DIR/run/agent.pid)"
    ($DATADOG_DIR/agent stop --cfgpath $DATADOG_DIR/dist/) || true
    find_pid_kill_and_wait $DATADOG_DIR/agent || true
    kill_and_wait "$DATADOG_DIR/run/agent.pid" 5
    rm -f "$DATADOG_DIR/run/agent.pid"
  fi

  if [ -f "$DATADOG_DIR/run/trace-agent.pid" ]; then
    echo "Stopping trace agent process, pid: $(cat $DATADOG_DIR/run/trace-agent.pid)"
    trace_agent_command="$DATADOG_DIR/trace-agent"
    kill_and_wait "$DATADOG_DIR/run/trace-agent.pid" 5 1
    find_pid_kill_and_wait $trace_agent_command "$DATADOG_DIR/run/trace-agent.pid"
  fi

  if [ -f "$DATADOG_DIR/run/dogstatsd.pid" ]; then
    echo "Stopping dogstatsd agent process, pid: $(cat $DATADOG_DIR/run/dogstatsd.pid)""
    dogstatsd_command="$DATADOG_DIR/dogstatsd"
    kill_and_wait "$DATADOG_DIR/run/dogstatsd.pid" 5 1
    find_pid_kill_and_wait $dogstatsd_command "$DATADOG_DIR/run/dogstatsd.pid"
  fi
}

start_datadog() {
  pushd $DATADOG_DIR

    export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
    export DD_API_KEY
    export DD_DD_URL
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-false}"
    export DOCKER_DD_AGENT=yes
    export LOGS_CONFIG_DIR=$DATADOG_DIR/dist/conf.d/logs.d
    export LOGS_CONFIG
    export DD_API_KEY

    if [ -a ./agent ] && { [ "$DD_LOGS_ENABLED" = "true" ] || [ "$DD_ENABLE_CHECKS" = "true" ]; }; then
      if [ "$DD_LOGS_ENABLED" = "true" -a "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=$DATADOG_DIR/agent.log
        export DD_IOT_HOST=false

        python $DATADOG_DIR/scripts/create_logs_config.py

        if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
          ./agent run --cfgpath $DATADOG_DIR/dist/ --pidfile $DATADOG_DIR/run/agent.pid > /dev/null 2>&1 &
        else
          ./agent run --cfgpath $DATADOG_DIR/dist/ --pidfile $DATADOG_DIR/run/agent.pid &
        fi
      fi
    else
      echo "Starting dogstatsd agent"
      export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
      if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
        ./dogstatsd start --cfgpath $DATADOG_DIR/dist/ > /dev/null 2>&1 &
      else
        ./dogstatsd start --cfgpath $DATADOG_DIR/dist/ &
      fi
      echo $! > run/dogstatsd.pid
    fi
    echo "Starting trace agent"
    if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
      ./trace-agent --config $DATADOG_DIR/dist/datadog.yaml --pid $DATADOG_DIR/run/trace-agent.pid > /dev/null 2>&1 &
    else
      ./trace-agent --config $DATADOG_DIR/dist/datadog.yaml --pid $DATADOG_DIR/run/trace-agent.pid &
    fi
  popd
}



main() {
    # After the tags are parsed and added to DD_TAGS, we need to restart the agent for the changes to take effect
    echo "stop datadog to refresh tags"
    stop_datadog
    echo "start datadog to refresh tags"
    start_datadog
}

main "$@" >> "${DATADOG_DIR}/update_script.log" 2>&1
