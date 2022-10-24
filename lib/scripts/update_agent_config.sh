#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

#set -e # exit immediately if a simple command exits with a non-zero status
#set -u # report the usage of uninitialized variables

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"
#source "$DATADOG_DIR/scripts/util.sh"

datadog_tags=$(python $DATADOG_DIR/scripts/get_tags.py node-agent-tags)
sed -i "s~tags: \[.*\].*~tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml
sed -i "s~dogstatsd_tags: \[.*\].*~dogstatsd_tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml

sed -i "s~tags: \[.*\].*~tags: $datadog_tags~" $DATADOG_DIR/dist/dogstatsd.yaml
sed -i "s~dogstatsd_tags: \[.*\].*~dogstatsd_tags: $datadog_tags~" $DATADOG_DIR/dist/dogstatsd.yaml

# wait_pid, find_pid, and find_pid_kill_and_wait are taken from
# https://github.com/DataDog/datadog-agent-boshrelease/blob/master/src/helpers/lib.sh

function wait_pid {
  local pidfile=$1
  local pid=$2
  local try_kill=$3
  local timeout=${4:-0}
  local force=${5:-0}
  local countdown=$(( $timeout * 10 ))
  local ps_out="$(ps ax | grep $pid | grep -v grep)"

  if [ -e /proc/$pid -o -n "$ps_out" ]; then
    if [ "$try_kill" = "1" ]; then
      echo "Killing $pidfile: $pid "
      kill $pid
    fi
    while [ -e /proc/$pid ]; do
      sleep 0.1
      [ "$countdown" != '0' -a $(( $countdown % 10 )) = '0' ] && echo -n .
      if [ $timeout -gt 0 ]; then
        if [ $countdown -eq 0 ]; then
          if [ "$force" = "1" ]; then
            echo
            echo "Kill timed out, using kill -9 on $pid ..."
            kill -9 $pid
            sleep 0.5
          fi
          break
        else
          countdown=$(( $countdown - 1 ))
        fi
      fi
    done
    if [ -e /proc/$pid ]; then
      echo "Timed Out"
    else
      echo "Stopped $pid"
    fi
  else
    echo "Process $pid is not running"
  fi
}

function find_pid {
  local find_command=$1
  local pid=$(pgrep -f $find_command)
  echo $pid
}

function wait_pidfile {
  local pidfile=$1
  local try_kill=$2
  local timeout=${3:-0}
  local force=${4:-0}
  local countdown=$(( $timeout * 10 ))

  if [ -f "$pidfile" ]; then
    pid=$(head -1 "$pidfile")
    if [ -z "$pid" ]; then
      die "Unable to get pid from $pidfile"
    fi
    wait_pid $pidfile $pid $try_kill $timeout $force
    rm -f $pidfile
  else
    printf_log "Pidfile $pidfile doesn't exist"
  fi
}

function kill_and_wait {
  local pidfile=$1
  local timeout=${2:-25}
  local force=${3:-1}

  if [ -f "${pidfile}" ]; then
    wait_pidfile $pidfile 1 $timeout $force
  else
    # TODO assume $1 is something to grep from 'ps ax'
    pid="$(ps auwwx | grep "'$1'" | awk '{print $2}')"
    wait_pid $pidfile $pid 1 $timeout $force
  fi
}


function find_pid_kill_and_wait {
  local find_command=$1
  local pidfile=$2
  local pid=$(find_pid $find_command)
  if [[ ! "$pid" || "$pid" == "" ]]; then
    echo "No such PID $pid exists, skipping the hard kill"
  else
    local timeout=${2:-25}
    local force=${3:-1}
    wait_pid $pidfile $pid 1 $timeout $force
  fi
}

stop_datadog() {
  echo "Stopping agent process, pid: $(cat $DATADOG_DIR/run/agent.pid)"
  $DATADOG_DIR/agent stop --cfgpath $DATADOG_DIR/dist/
  trace_agent_command="$DATADOG_DIR/trace-agent"
  dogstatsd_command="$DATADOG_DIR/dogstatsd"
  kill_and_wait "$DATADOG_DIR/run/agent.pid" 1
  rm -f "$DATADOG_DIR/run/agent.pid"

  kill_and_wait "$DATADOG_DIR/run/trace-agent.pid" 1 1
  find_pid_kill_and_wait $trace_agent_command "$DATADOG_DIR/run/trace-agent.pid"

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

    echo $DD_LOGS_VALID_ENDPOINT
    export DD_LOGS_VALID_ENDPOINT="true"
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

echo "Restarting datadog to refresh tags"
stop_datadog
start_datadog
