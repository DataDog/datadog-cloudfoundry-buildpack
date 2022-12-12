#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

export DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
export DEBUG_FILE="${DATADOG_DIR}/update_agent_script.log"

log_message() {
  local component=$1
  local message=$3
  echo "$(date +'%d-%m-%Y %H:%M:%S') - [${1#/home/vcap/app/}][PID:$2] - ${4:-INFO} - $3"
}