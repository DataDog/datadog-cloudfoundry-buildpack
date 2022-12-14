#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

export DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
export DEBUG_FILE="${DATADOG_DIR}/update_agent_script.log"

log_message() {
  local component="${1#/home/vcap/app/}"
  local pid="$2"
  local message="$3"
  local log_level="${4:-INFO}"
  echo "$(date +'%d-%m-%Y %H:%M:%S') - [${component}][PID:${pid}] - ${log_level} - ${message}"
}