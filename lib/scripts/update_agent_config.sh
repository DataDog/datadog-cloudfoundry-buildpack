#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"
export DD_TAGS=$(LEGACY_TAGS_FORMAT=true python $DATADOG_DIR/scripts/get_tags.py)

datadog_tags=$(python $DATADOG_DIR/scripts/get_tags.py node-agent-tags)
sed -i "s~tags: \[.*?\].*~tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml
sed -i "s~dogstatsd_tags: \[.*?\].*~dogstatsd_tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml

stop_datadog() {
  for pidfile in "$DATADOG_DIR"/run/*; do
    kill $(cat $pidfile)
  done
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

echo "restarting datadog to refresh tags"
stop_datadog
start_datadog
