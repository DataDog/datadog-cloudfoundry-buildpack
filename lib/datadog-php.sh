#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

# Datadog PHP single-step APM instrumentation.
# Sourced as .profile.d/99-datadog-php.sh, after php_buildpack's own profile
# scripts so PATH and LD_LIBRARY_PATH point at the buildpack's PHP runtime.
# Calls the official installer documented at
# https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/php/.

if [ -z "${DD_APM_INSTRUMENTATION_ENABLED:-}" ] || [ "${DD_APM_INSTRUMENTATION_ENABLED}" = "false" ]; then
  return 0
fi

if [ -z "${DEPS_DIR:-}" ]; then
  return 0
fi

php_buildpack_found=""
for dir in "${DEPS_DIR}"/*/; do
  if grep -q -E '^name: php$' "${dir%/}/config.yml" 2>/dev/null; then
    php_buildpack_found="true"
    break
  fi
done
if [ -z "$php_buildpack_found" ]; then
  return 0
fi

if ! command -v php >/dev/null 2>&1; then
  echo "[datadog-php] php not on PATH, skipping ddtrace install"
  return 0
fi

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
DD_TRACE_PHP_VERSION="${DD_TRACE_PHP_VERSION:-1.19.2}"
INSTALLER="${DATADOG_DIR}/datadog-setup.php"
INSTALLER_URL="https://github.com/DataDog/dd-trace-php/releases/download/${DD_TRACE_PHP_VERSION}/datadog-setup.php"

if ! curl -fsSL "$INSTALLER_URL" -o "$INSTALLER"; then
  echo "[datadog-php] failed to download $INSTALLER_URL"
  return 0
fi

installer_args="--php-bin=$(command -v php)"
if [ "${DD_PROFILING_ENABLED:-}" = "true" ]; then
  installer_args="${installer_args} --enable-profiling"
fi

php "$INSTALLER" $installer_args
