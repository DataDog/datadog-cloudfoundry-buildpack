#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
LOCKFILE="${DATADOG_DIR}/startup_scripts.lock"

exec 7> "${LOCKFILE}" || exit 0

if flock -x -n 7; then
    source "${DATADOG_DIR}/startup_scripts/00-test-endpoint.sh"
    source "${DATADOG_DIR}/startup_scripts/02-redirect-logs.sh"
    source "${DATADOG_DIR}/startup_scripts/01-run-datadog.sh"
fi