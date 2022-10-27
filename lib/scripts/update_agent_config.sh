#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# This script is called by the node agent to expose CAPI metadata and DCA tags to the container agents
# It sets the DD_NODE_AGENT_TAGS environment variable with these new tags 
# see: https://github.com/DataDog/datadog-agent/blob/7.40.x/pkg/cloudfoundry/containertagger/container_tagger.go#L131
DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"

# import utility functions
source "$DATADOG_DIR/scripts/utils.sh"

datadog_tags=$(python $DATADOG_DIR/scripts/get_tags.py node-agent-tags)
sed -i "s~tags: \[.*\].*~tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml
sed -i "s~dogstatsd_tags: \[.*\].*~dogstatsd_tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml

sed -i "s~tags: \[.*\].*~tags: $datadog_tags~" $DATADOG_DIR/dist/dogstatsd.yaml
sed -i "s~dogstatsd_tags: \[.*\].*~dogstatsd_tags: $datadog_tags~" $DATADOG_DIR/dist/dogstatsd.yaml

echo $datadog_tags > "$DATADOG_DIR/node_agent_tags.txt"

stop_datadog() {
  echo "Stopping agent process, pid: $(cat $DATADOG_DIR/run/agent.pid)"

  # first try to stop the agent so we don't lose data and then force it
  ($DATADOG_DIR/agent stop --cfgpath $DATADOG_DIR/dist/) || true
  find_pid_kill_and_wait $DATADOG_DIR/agent || true
  kill_and_wait "$DATADOG_DIR/run/agent.pid" 1
  rm -f "$DATADOG_DIR/run/agent.pid"

  trace_agent_command="$DATADOG_DIR/trace-agent"
  kill_and_wait "$DATADOG_DIR/run/trace-agent.pid" 1 1
  find_pid_kill_and_wait $trace_agent_command "$DATADOG_DIR/run/trace-agent.pid"

  dogstatsd_command="$DATADOG_DIR/dogstatsd"
  kill_and_wait "$DATADOG_DIR/run/dogstatsd.pid" 1 1
  find_pid_kill_and_wait $dogstatsd_command "$DATADOG_DIR/run/dogstatsd.pid"
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

    datadog_tags=$(python $DATADOG_DIR/scripts/create_logs_config.py)
    unset DD_TAGS

    if [ -a ./agent ] && { [ "$DD_LOGS_ENABLED" = "true" ] || [ "$DD_ENABLE_CHECKS" = "true" ]; }; then
      if [ "$DD_LOGS_ENABLED" = "true" -a "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=$DATADOG_DIR/agent.log
        export DD_IOT_HOST=false
        if [ "$SUPPRESS_DD_AGENT_OUTPUT" == "true" ]; then
          ./agent run --cfgpath $DATADOG_DIR/dist/ --pidfile $DATADOG_DIR/run/agent.pid > /dev/null 2>&1 &
        else
          ./agent run --cfgpath $DATADOG_DIR/dist/ --pidfile $DATADOG_DIR/run/agent.pid &
        fi
      fi
    else
      export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
      if [ "$SUPPRESS_DD_AGENT_OUTPUT" == "true" ]; then
        ./dogstatsd start --cfgpath $DATADOG_DIR/dist/ > /dev/null 2>&1 &
      else
        ./dogstatsd start --cfgpath $DATADOG_DIR/dist/ &
      fi
      echo $! > run/dogstatsd.pid
    fi
    if [ "$SUPPRESS_DD_AGENT_OUTPUT" == "true" ]; then
      ./trace-agent --config $DATADOG_DIR/dist/datadog.yaml --pid $DATADOG_DIR/run/trace-agent.pid > /dev/null 2>&1 &
    else
      ./trace-agent --config $DATADOG_DIR/dist/datadog.yaml --pid $DATADOG_DIR/run/trace-agent.pid &
    fi
  popd
}

# After the tags are parsed and added to the agent config, we need to restart the agent for the changes to take effect 
echo "Restarting datadog to refresh tags"
stop_datadog
start_datadog
