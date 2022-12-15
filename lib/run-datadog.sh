#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"
LOCKFILE="${DATADOG_DIR}/lock"

export DD_TAGS=$(LEGACY_TAGS_FORMAT=true python "${DATADOG_DIR}"/scripts/get_tags.py)
FIRST_RUN=${FIRST_RUN:-true}

source $DATADOG_DIR/scripts/common.sh
source $DATADOG_DIR/scripts/utils.sh

setup_datadog() {
  pushd "${DATADOG_DIR}"

    export DD_LOG_FILE="${DATADOG_DIR}/dogstatsd.log"
    export DD_API_KEY
    export DD_DD_URL
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-false}"
    export DOCKER_DD_AGENT=yes
    export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
    export LOGS_CONFIG

    # create and configure set /conf.d if integrations are enabled
    if [ "$DD_ENABLE_CHECKS" = "true" ] || [ -n "$LOGS_CONFIG" ] ; then
      mkdir dist/conf.d
    fi

    # add checks configs
    if [ "$DD_ENABLE_CHECKS" = "true" ]; then
      mv conf.d/* dist/conf.d
    fi

    # add logs configs
    if [ -n "$LOGS_CONFIG" ]; then
      mkdir -p $LOGS_CONFIG_DIR
      ruby scripts/create_logs_config.rb 2>&1 | tee -a "$DATADOG_DIR/ruby_script.1.log"
    fi

    # The yaml file requires the tags to be an array,
    # the conf file requires them to be comma separated only
    # so they must be grabbed separately
    sed -i "s~log_file: TRACE_LOG_FILE~log_file: ${DATADOG_DIR}/trace.log~" dist/datadog.yaml

    if [ -n "$DD_SKIP_SSL_VALIDATION" ]; then
      sed -i "s~# skip_ssl_validation: no~skip_ssl_validation: yes~" dist/datadog.yaml
    fi

    # set logs, traces and metrics hostname to the VM hostname
    if [ "$DD_ENABLE_CHECKS" != "true" ]; then
      sed -i "s~# enable_metadata_collection: true~enable_metadata_collection: false~" dist/datadog.yaml
      host "$CF_INSTANCE_IP"
      if [ $? -eq 0 ]; then
          IFS=. read -a VM_HOSTNAME <<< $(host $CF_INSTANCE_IP | awk '{print $5}')
          sed -i "s~# hostname: mymachine.mydomain~hostname: $VM_HOSTNAME~" dist/datadog.yaml
      fi
    else
      sed -i "s~# hostname: mymachine.mydomain~hostname: $(hostname)~" dist/datadog.yaml
    fi

    if [ -n "$DD_HTTP_PROXY" ]; then
      sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
      sed -i "s~#   http: HTTP_PROXY~  http: $DD_HTTP_PROXY~" dist/datadog.yaml
    else
      if [ -n "$HTTP_PROXY" ]; then
        sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
        sed -i "s~#   http: HTTP_PROXY~  http: $HTTP_PROXY~" dist/datadog.yaml
      fi
    fi
    if [ -n "$DD_HTTPS_PROXY" ]; then
      sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
      sed -i "s~#   https: HTTPS_PROXY~  https: $DD_HTTPS_PROXY~" dist/datadog.yaml
    else
      if [ -n "$HTTPS_PROXY" ]; then
        sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
        sed -i "s~#   https: HTTPS_PROXY~  https: $HTTPS_PROXY~" dist/datadog.yaml
      fi
    fi

    #Override default EXPVAR Port
    if [ -n "$DD_EXPVAR_PORT" ]; then
      sed -i "s~# expvar_port: 5000~expvar_port: $DD_EXPVAR_PORT~" dist/datadog.yaml
    fi
    #Override default CMD Port
    if [ -n "$DD_CMD_PORT" ]; then
      sed -i "s~# cmd_port: 5001~cmd_port: $DD_CMD_PORT~" dist/datadog.yaml
    fi

    # Create folder for storing PID files
    mkdir run

    # DSD requires its own config file
    cp dist/datadog.yaml dist/dogstatsd.yaml

    if [ -a ./agent ] && { [ "$DD_LOGS_ENABLED" = "true" ] || [ "$DD_ENABLE_CHECKS" = "true" ]; }; then
      if [ "$DD_LOGS_ENABLED" = "true" -a "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=${DATADOG_DIR}/agent.log
        export DD_IOT_HOST=false
        sed -i "s~log_file: AGENT_LOG_FILE~log_file: $DD_LOG_FILE~" dist/datadog.yaml
      fi
    else
      export DD_LOG_FILE=${DATADOG_DIR}/dogstatsd.log
      sed -i "s~log_file: AGENT_LOG_FILE~log_file: $DD_LOG_FILE~" dist/datadog.yaml
    fi
  popd
}

start_datadog() {
  pushd ${DATADOG_DIR}
    export DD_LOG_FILE="${DATADOG_DIR}/dogstatsd.log"
    export DD_API_KEY
    export DD_DD_URL
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-false}"
    export DOCKER_DD_AGENT=yes
    export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
    export LOGS_CONFIG

    if [ "${FIRST_RUN}" = "true" ]; then
      echo "First run datadog"
      setup_datadog
      FIRST_RUN=false
    else
      echo "Not first run datadog"
      if [ -f  "${DATADOG_DIR}/.sourced_datadog_env" ]; then
        source "${DATADOG_DIR}/.sourced_datadog_env"
      elif [ -f  "${DATADOG_DIR}/.datadog_env" ]; then
        source "${DATADOG_DIR}/.datadog_env"
      fi
    fi

    if [ -a ./agent ] && { [ "$DD_LOGS_ENABLED" = "true" ] || [ "$DD_ENABLE_CHECKS" = "true" ]; }; then
      if [ "$DD_LOGS_ENABLED" = "true" -a "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=agent.log
        export DD_IOT_HOST=false

        echo "Starting Datadog agent"
        ruby scripts/create_logs_config.rb 2>&1 | tee -a "$DATADOG_DIR/ruby_script.4.log"

        if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
          ./agent run --cfgpath dist/ --pidfile run/agent.pid > /dev/null 2>&1 &
        else
          ./agent run --cfgpath dist/ --pidfile run/agent.pid &
        fi
      fi
    else
      echo "Starting dogstatsd agent"
      export DD_LOG_FILE=dogstatsd.log
      if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
        ./dogstatsd start --cfgpath dist/ > /dev/null 2>&1 &
      else
        ./dogstatsd start --cfgpath dist/ &
      fi
      echo $! > run/dogstatsd.pid
    fi
    echo "Starting trace agent"
    if [ "$SUPPRESS_DD_AGENT_OUTPUT" = "true" ]; then
      ./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid > /dev/null 2>&1 &
    else
      ./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid &
    fi
  popd
}


stop_datadog() {
  pushd "${DATADOG_DIR}"
    if kill -0 $(cat ${DATADOG_DIR}/run/agent.pid) > /dev/null; then
      echo "Stopping agent process, pid: $(cat run/agent.pid)"
      # first try to stop the agent so we don't lose data and then force it
      (./agent stop --cfgpath dist/) || true
      agent_command="./agent run --cfgpath dist/ --pidfile run/agent.pid"
      find_pid_kill_and_wait "$agent_command" "${DATADOG_DIR}/run/agent.pid" 5 1 || true
      kill_and_wait "${DATADOG_DIR}/run/agent.pid" 5 1
      rm -f "run/agent.pid"
    fi

    if kill -0 $(cat "${DATADOG_DIR}/run/dogstatsd.pid") > /dev/null; then
      echo "Stopping dogstatsd agent process, pid: $(cat run/dogstatsd.pid)"
      dogstatsd_command="./dogstatsd start --cfgpath dist/"
      kill_and_wait "${DATADOG_DIR}/run/dogstatsd.pid" 5 1
      find_pid_kill_and_wait "${dogstatsd_command}" "${DATADOG_DIR}/run/dogstatsd.pid" 5 1 
      rm -f "run/dogstatsd.pid"
    fi

    if kill -0 $(cat "${DATADOG_DIR}/run/trace-agent.pid"); then
      echo "Stopping trace agent process, pid: $(cat run/trace-agent.pid)"
      trace_agent_command="./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid"
      kill_and_wait "${DATADOG_DIR}/run/trace-agent.pid" 5 1
      find_pid_kill_and_wait "${trace_agent_command}" "${DATADOG_DIR}/run/trace-agent.pid" 5 1
      rm -f "run/trace-agent.pid"
    fi
  popd
}


monit_datadog() {
  while true; do
    if ! kill -0 $$; then
      echo "main process exited, stopping agent"
      for pidfile in "${DATADOG_DIR}"/run/*; do
        kill $(cat $pidfile)
      done
      exit
    elif [ -f "${DATADOG_DIR}"/tags_updated ]; then
      echo "STOPPING DATADOG"
      stop_datadog
      echo "STARTING DATADOG"
      start_datadog
      rm -f "${DATADOG_DIR}"/tags_updated
    fi
    sleep 1
  done
}

main() {
  if [ -z "$DD_API_KEY" ]; then
    echo "Datadog API Key not set, not starting Datadog"
  else
    exec 9> "$LOCKFILE" || exit 1
    if flock -x -n 9; then
      echo "starting datadog"
      start_datadog
      monit_datadog &
      exec 9>&-
    fi
  fi
}
main "$@"
