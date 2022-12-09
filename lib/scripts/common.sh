#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

log_message() {
  local component=$1
  local message=$2
  echo "$(date +'%d/%m/%Y %H:%M:%S') [${1#/home/vcap/app/}] - ${3:-INFO} - $2"
}