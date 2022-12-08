#!/usr/bin/env bash

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

log_message() {
  local component=$1
  local message=$2
  echo "$(date +'%d/%m/%Y %H:%M:%S') [${1#/home/vcap/app/}] - ${3:-INFO} - ${2}"
}