#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
SUPPRESS_DD_AGENT_OUTPUT="${SUPPRESS_DD_AGENT_OUTPUT:-true}"
DD_ENABLE_CAPI_METADATA_COLLECTION="${DD_ENABLE_CAPI_METADATA_COLLECTION:-false}"
LOCKFILE="${DATADOG_DIR}/lock"
FIRST_RUN="${FIRST_RUN:-true}"
USER_TAGS="${DD_TAGS}"

. "${DATADOG_DIR}/scripts/utils.sh"

# source updated PATH
. "$DATADOG_DIR/.global_env"

export DD_TAGS=$(ruby "${DATADOG_DIR}/scripts/get_tags.rb")
echo "${DD_TAGS}" > "${DATADOG_DIR}/.dd_tags.txt"

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
    if [ "${DD_ENABLE_CHECKS}" = "true" ] || [ -n "${LOGS_CONFIG}" ] ; then
      mkdir dist/conf.d
    fi

    # add checks configs
    if [ "${DD_ENABLE_CHECKS}" = "true" ]; then
      mv conf.d/* dist/conf.d
    fi

    # add logs configs
    if [ -n "${LOGS_CONFIG}" ]; then
      mkdir -p ${LOGS_CONFIG_DIR}
      echo "creating logs config"
      ruby "${DATADOG_DIR}/scripts/create_logs_config.rb"
    fi

    # The yaml file requires the tags to be an array,
    # the conf file requires them to be comma separated only
    # so they must be grabbed separately
    sed -i "s~log_file: TRACE_LOG_FILE~log_file: ${DATADOG_DIR}/trace.log~" dist/datadog.yaml

    if [ -n "${DD_SKIP_SSL_VALIDATION}" ]; then
      sed -i "s~# skip_ssl_validation: no~skip_ssl_validation: yes~" dist/datadog.yaml
    fi

    # set logs, traces and metrics hostname to the VM hostname
    if [ "${DD_ENABLE_CHECKS}" != "true" ]; then
      sed -i "s~# enable_metadata_collection: true~enable_metadata_collection: false~" dist/datadog.yaml
      host "${CF_INSTANCE_IP}"
      if [ $? -eq 0 ]; then
          IFS=. read -a VM_HOSTNAME <<< $(host ${CF_INSTANCE_IP} | awk '{print $5}')
          sed -i "s~# hostname: mymachine.mydomain~hostname: ${VM_HOSTNAME}~" dist/datadog.yaml
      fi
    else
      sed -i "s~# hostname: mymachine.mydomain~hostname: $(hostname)~" dist/datadog.yaml
    fi

    if [ -n "${DD_HTTP_PROXY}" ]; then
      sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
      sed -i "s~#   http: HTTP_PROXY~  http: ${DD_HTTP_PROXY}~" dist/datadog.yaml
    else
      if [ -n "${HTTP_PROXY}" ]; then
        sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
        sed -i "s~#   http: HTTP_PROXY~  http: ${HTTP_PROXY}~" dist/datadog.yaml
      fi
    fi
    if [ -n "${DD_HTTPS_PROXY}" ]; then
      sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
      sed -i "s~#   https: HTTPS_PROXY~  https: ${DD_HTTPS_PROXY}~" dist/datadog.yaml
    else
      if [ -n "${HTTPS_PROXY}" ]; then
        sed -i "s~# proxy:~proxy:~" dist/datadog.yaml
        sed -i "s~#   https: HTTPS_PROXY~  https: ${HTTPS_PROXY}~" dist/datadog.yaml
      fi
    fi

    #Override default EXPVAR Port
    if [ -n "${DD_EXPVAR_PORT}" ]; then
      sed -i "s~# expvar_port: 5000~expvar_port: ${DD_EXPVAR_PORT}~" dist/datadog.yaml
    fi
    #Override default CMD Port
    if [ -n "${DD_CMD_PORT}" ]; then
      sed -i "s~# cmd_port: 5001~cmd_port: ${DD_CMD_PORT}~" dist/datadog.yaml
    fi

    # Create folder for storing PID files
    mkdir run

    if [ -a ./agent ] && { [ "${DD_LOGS_ENABLED}" = "true" ] || [ "${DD_ENABLE_CHECKS}" = "true" ]; }; then
      if [ "${DD_LOGS_ENABLED}" = "true" -a "${DD_LOGS_VALID_ENDPOINT}" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=${DATADOG_DIR}/agent.log
        export DD_IOT_HOST=false
        sed -i "s~log_file: AGENT_LOG_FILE~log_file: ${DD_LOG_FILE}~" dist/datadog.yaml
      fi
    else
      export DD_LOG_FILE=${DATADOG_DIR}/dogstatsd.log
      sed -i "s~log_file: AGENT_LOG_FILE~log_file: ${DD_LOG_FILE}~" dist/datadog.yaml
    fi
  popd

  # update datadog config
  ruby "${DATADOG_DIR}/scripts/update_datadog_config.rb"

  # mark the script as finished, useful to sync the update_agent_config script
  touch "${DATADOG_DIR}/.setup_completed"

}

start_datadog() {
  export DD_TAGS=$(ruby "${DATADOG_DIR}/scripts/get_tags.rb")

  pushd "${DATADOG_DIR}"
    export DD_LOG_FILE="${DATADOG_DIR}/dogstatsd.log"
    export DD_API_KEY
    export DD_DD_URL
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-false}"
    export DOCKER_DD_AGENT=yes
    export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
    export LOGS_CONFIG

    if [ "${FIRST_RUN}" = "true" ]; then
      date +%s > "${DATADOG_DIR}/startup_time"
      echo "setting up datadog"
      setup_datadog
    else
      if [ -f  "${DATADOG_DIR}/.sourced_datadog_env" ]; then
        echo "sourcing .sourced_datadog_env file"
        safe_source "${DATADOG_DIR}/.sourced_datadog_env"
      elif [ -f  "${DATADOG_DIR}/.datadog_env" ]; then
        echo "sourcing .datadog_env file"
        safe_source "${DATADOG_DIR}/.datadog_env"
      fi
    fi

    if [ -a ./agent ] && { [ "${DD_LOGS_ENABLED}" = "true" ] || [ "${DD_ENABLE_CHECKS}" = "true" ]; }; then
      if [ "${DD_LOGS_ENABLED}" = "true" ] && [ "${DD_LOGS_VALID_ENDPOINT}" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE="${DATADOG_DIR}/agent.log"
        export DD_IOT_HOST=false

        echo "Starting Datadog agent"
        if [ "${SUPPRESS_DD_AGENT_OUTPUT}" = "true" ]; then
          env -u DD_TAGS ./agent run --cfgpath dist/ --pidfile run/agent.pid > /dev/null 2>&1 &
        else
          env -u DD_TAGS ./agent run --cfgpath dist/ --pidfile run/agent.pid &
        fi
      fi
    else
      echo "Starting dogstatsd agent"
      export DD_LOG_FILE="${DATADOG_DIR}/dogstatsd.log"
      if [ "${SUPPRESS_DD_AGENT_OUTPUT}" = "true" ]; then
        env -u DD_TAGS ./dogstatsd start --cfgpath dist/datadog.yaml > /dev/null 2>&1 &
      else
        env -u DD_TAGS ./dogstatsd start --cfgpath dist/datadog.yaml &
      fi
      echo $! > run/dogstatsd.pid
    fi
    if [ "${FIRST_RUN}" = "true" ]; then
      echo "Starting trace agent"
      if [ "${SUPPRESS_DD_AGENT_OUTPUT}" = "true" ]; then
        env -u DD_TAGS ./trace-agent run --config dist/datadog.yaml --pidfile run/trace-agent.pid > /dev/null 2>&1 &
      else
        env -u DD_TAGS ./trace-agent run --config dist/datadog.yaml --pidfile run/trace-agent.pid &
      fi
      FIRST_RUN=false
    fi
  popd
}

stop_datadog() {
  pushd "${DATADOG_DIR}"
    if check_if_running "${AGENT_PIDFILE}" "${AGENT_CMD}"; then
      echo "Stopping agent process, pid: $(cat "${AGENT_PIDFILE}")"
      # first try to stop the agent so we don't lose data and then force it
      (./agent stop --cfgpath dist/) || true
      find_pid_kill_and_wait "${AGENT_CMD}" "${AGENT_PIDFILE}" 5 1 || true
      kill_and_wait "${AGENT_PIDFILE}" 5 1
      rm -f "${AGENT_PIDFILE}"
    fi

    if check_if_running "${DOGSTATSD_PIDFILE}" "${DOGSTATSD_CMD}"; then
      echo "Stopping dogstatsd agent process, pid: $(cat "${DOGSTATSD_PIDFILE}")"
      kill_and_wait "${DOGSTATSD_PIDFILE}" 5 1
      find_pid_kill_and_wait "${DOGSTATSD_CMD}" "${DOGSTATSD_PIDFILE}" 5 1
      rm -f "${DOGSTATSD_PIDFILE}"
    fi
  popd
}

monit_datadog() {
  while true; do
    if ! kill -0 $$; then
      echo "main process exited, stopping agent"
      for pidfile in "${DATADOG_DIR}"/run/*; do
        kill "$(cat "${pidfile}")"
      done
      exit
    elif [ -f "${DATADOG_DIR}"/tags_updated ]; then
      echo "tags_updated found, stopping datadog agents"
      stop_datadog
      echo "tags_updated found, starting datadog agents"
      start_datadog
      echo "deleting tags_updated"
      rm -f "${DATADOG_DIR}"/tags_updated # TODO: check for race conditions
    fi
    sleep 1
  done
}

main() {
  if [ -z "${DD_API_KEY}" ]; then
    echo "Datadog API Key not set, not starting Datadog"
  else
    exec 9> "${LOCKFILE}" || exit 1
    if flock -x -n 9; then
      echo "starting datadog"
      start_datadog
      monit_datadog &
      exec 9>&-
    fi
  fi

  # wait for the trace agent startup
  if [ "${DD_WAIT_TRACE_AGENT}" = "true" ]; then
    timeout=120
    while ! nc -z localhost 8126 && [ $timeout -ge 0 ]; do
      echo "Waiting for the trace agent to start on 8126..."
      sleep 1
      timeout=$((timeout - 1))
    done
    if [ $timeout -ge 0 ]; then
        echo "Trace agent is listening for traces"
    else
        echo "Timed out waiting for the trace agent"
    fi
  fi
}
main "$@"


