#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# These utils are taken from
# https://github.com/DataDog/datadog-agent-boshrelease/blob/4.11.2/src/helpers/lib.sh

export DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
export LOGS_CONFIG_DIR="${DATADOG_DIR}/dist/conf.d/logs.d"
export LOGS_CONFIG

export AGENT_PIDFILE="${DATADOG_DIR}/run/agent.pid"
export AGENT_CMD="./agent run --cfgpath dist/ --pidfile run/agent.pid"

export TRACE_AGENT_PIDFILE="${DATADOG_DIR}/run/trace-agent.pid"
export TRACE_AGENT_CMD="./trace-agent --config dist/datadog.yaml --pid run/trace-agent.pid"

export DOGSTATSD_PIDFILE="${DATADOG_DIR}/run/dogstatsd.pid"
export DOGSTATSD_CMD="./dogstatsd start --cfgpath dist/"

dd_export_env() {
  local env_file="$1"

  DD_SHARED_ENV_VARS=(
    "DD_ENABLE_CAPI_METADATA_COLLECTION"
    "DD_TAGS"
    "DD_DOGSTATSD_TAGS"
    "LOGS_CONFIG_DIR"
    "LOGS_CONFIG"
    "VCAP_APPLICATION"
    "CF_INSTANCE_IP"
    "CF_INSTANCE_GUID" # not available during staging
    "DD_UPDATE_SCRIPT_WARMUP"
    "TAGS"
    "LEGACY_TAGS_FORMAT"
  )

  rm "${env_file}"

  for shared_var in "${DD_SHARED_ENV_VARS[@]}"; do
    shared_var_value="$(eval "${shared_var}")"
    if [ -n "${shared_var_value}" ]; then
      echo "export ${shared_var}='${shared_var_value}'" >> "${env_file}"   
    fi
  done
}

safe_source() {
  local source_file="$1"
  
  while IFS= read -r line; do
    eval "$line";
  done < "${source_file}"
}

log_info() {
  log_message "$0" "$$" "$@" "INFO"
}

log_debug() {
  log_message "$0" "$$" "$@" "DEBUG"
}

log_error() {
  log_message "$0" "$$" "$@" "ERROR" 1>&2
}

log_message() {
  local component="${1#/home/vcap/app/}"
  local pid="$2"
  local message="$3"
  local log_level="$4"
  echo "$(date +'%d-%m-%Y %H:%M:%S') - [${component}][PID:${pid}] - ${log_level} - ${message}"
}

check_if_running() {
  local pidfile="$1"
  local command="${2:-none}"
  
  if [ -f "${pidfile}" ]; then
    kill -0 "$(cat "${pidfile}")" > /dev/null
  else
    pgrep -f "${command}"
  fi
}

wait_pid() {
  local pidfile="$1"
  local pid="$2"
  local try_kill="$3"
  local timeout="${4:-0}"
  local force="${5:-0}"
  local countdown=$(( ${timeout} * 10 ))
  local ps_out="$(ps ax | grep ${pid} | grep -v grep)"

  if [ -e "/proc/${pid}" ] || [ -n "${ps_out}" ]; then
    if [ "${try_kill}" = "1" ]; then
      log_message "$0" "Killing ${pidfile}: ${pid}"
      kill "${pid}"
    fi
    while [ -e "/proc/${pid}" ]; do
      sleep 0.1
      [ "${countdown}" != '0' ] && [ $(( "${countdown}" % 10 )) = '0' ] && echo -n .
      if [ "${timeout}" -gt 0 ]; then
        if [ "${countdown}" -eq 0 ]; then
          if [ "${force}" = "1" ]; then
            echo
            log_message "$0" "Kill timed out, using kill -9 on ${pid} ..."
            kill -9 "${pid}"
            sleep 0.5
          fi
          break
        else
          countdown=$(( "${countdown}" - 1 ))
        fi
      fi
    done
    if [ -e "/proc/${pid}" ]; then
      log_message "$0" "Timed Out"
    else
      log_message "$0" "Stopped ${pid}"
    fi
  else
    log_message "$0" "Process ${pid} is not running"
  fi
}

find_pid() {
  local find_command="$1"
  local pid=$(pgrep -f "${find_command}")
  echo "${pid:-None}"
}

wait_pidfile() {
  local pidfile="$1"
  local try_kill="$2"
  local timeout="${3:-0}"
  local force="${4:-0}"
  local countdown=$(( "${timeout}" * 10 ))

  if [ -f "${pidfile}" ]; then
    pid=$(head -1 "${pidfile}")
    if [ -z "${pid}" ]; then
      die "Unable to get pid from ${pidfile}"
    fi
    wait_pid "${pidfile}" "${pid}" "${try_kill}" "${timeout}" "${force}"
    rm -f "${pidfile}"
  else
    printf_log "Pidfile ${pidfile} doesn't exist"
  fi
}

kill_and_wait() {
  local pidfile="$1"
  local timeout="${2:-25}"
  local force="${3:-1}"

  if [ -f "${pidfile}" ]; then
    wait_pidfile "${pidfile}" 1 "${timeout}" "${force}"
  else
    # TODO assume $1 is something to grep from 'ps ax'
    pid="$(ps auwwx | grep "'$1'" | awk '{print $2}')"
    wait_pid "${pidfile}" "${pid}" 1 "${timeout}" "${force}"
  fi
}


find_pid_kill_and_wait() {
  local find_command="$1"
  local pidfile="$2"
  local pid=$(find_pid "${find_command}")
  if [ -z "${pid}" ] || [ "${pid}" = "" ] ||  [ "${pid}" = "None" ]; then
    log_message "$0" "No such PID ${pid} exists, skipping the hard kill"
  else
    local timeout="${3:-25}"
    local force="${4:-1}"
    wait_pid "${pidfile}" "${pid}" 1 "${timeout}" "${force}"
  fi
}

# redirect forwards all standard inputs to a TCP socket listening on port STD_LOG_COLLECTION_PORT.
redirect() {
  while kill -0 $$; do
    if [ "${DD_SPARSE_APP_LOGS}" = "true" ]; then
        python "${DATADOG_DIR}/scripts/nc.py" "${STD_LOG_COLLECTION_PORT}" || sleep 0.5
    else
        nc localhost "${STD_LOG_COLLECTION_PORT}" || sleep 0.5
    fi
    log_info "Resetting buildpack log redirection"
    if [ "${DD_DEBUG_STD_REDIRECTION}" = "true" ]; then
      HTTP_PROXY=${DD_HTTP_PROXY} HTTPS_PROXY=${DD_HTTPS_PROXY} NO_PROXY=${DD_NO_PROXY} curl \
      -X POST -H "Content-type: application/json" \
      -d "{
            \"title\": \"Resetting buildpack log redirection\",
            \"text\": \"TCP socket on port ${STD_LOG_COLLECTION_PORT} for log redirection closed. Restarting it.\",
            \"priority\": \"normal\",
            \"tags\": $(python ${DATADOG_DIR}/scripts/get_tags.py),
            \"alert_type\": \"info\"
      }" "${DD_API_SITE}v1/events?api_key=${DD_API_KEY}"
    fi
  done
}
