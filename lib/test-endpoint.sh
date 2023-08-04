#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

# source updated PATH
. "$DATADOG_DIR/.global_env"

unset DD_LOGS_VALID_ENDPOINT
DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
DD_EU_API_SITE="https://api.datadoghq.eu/api/"
DD_US_API_SITE="https://api.datadoghq.com/api/"
DD_API_SITE=${DD_US_API_SITE}
DD_USE_EU=false

# Sets variable in order of DD_PROXY_HTTP -> DD_HTTP_PROXY -> HTTP_PROXY
DD_PROXY_HTTP_VAR=${DD_PROXY_HTTP:-${DD_HTTP_PROXY}}
DD_PROXY_HTTP_VAR=${DD_PROXY_HTTP_VAR:-${HTTP_PROXY}}

# Sets variable in order of DD_PROXY_HTTPS -> DD_HTTPS_PROXY -> HTTPS_PROXY
DD_PROXY_HTTPS_VAR=${DD_PROXY_HTTPS:-${DD_HTTPS_PROXY}}
DD_PROXY_HTTPS_VAR=${DD_PROXY_HTTPS_VAR:-${HTTPS_PROXY}}

DD_STRIPPED_PROXY_HTTPS="${DD_PROXY_HTTPS_VAR//https:\/\/}"
DD_STRIPPED_PROXY_HTTPS="${DD_STRIPPED_PROXY_HTTPS//http:\/\/}"

# Default endpoints can be found in DD Docs - https://docs.datadoghq.com/agent/logs/
DD_DEFAULT_HTTPS_EU_ENDPOINT="agent-http-intake.logs.datadoghq.eu:443"
DD_DEFAULT_HTTPS_US_ENDPOINT="agent-http-intake.logs.datadoghq.com:443"
DD_DEFAULT_TCP_EU_ENDPOINT="agent-intake.logs.datadoghq.eu:443"
DD_DEFAULT_TCP_US_ENDPOINT="agent-intake.logs.datadoghq.com:10516"

if [ "${DD_SITE}" = "datadoghq.eu" ]; then
  DD_USE_EU=true
  DD_API_SITE=${DD_EU_API_SITE}
fi

if [ "${DD_LOGS_CONFIG_USE_HTTP}" = true ]; then
  if [ -n "${DD_STRIPPED_PROXY_HTTPS}" ]; then
    DEFAULT_LOGS_ENDPOINT="${DD_STRIPPED_PROXY_HTTPS}"
  else
    if [ "${DD_USE_EU}" = true ]; then
      DEFAULT_LOGS_ENDPOINT="${DD_DEFAULT_HTTPS_EU_ENDPOINT}"
    else
      DEFAULT_LOGS_ENDPOINT="${DD_DEFAULT_HTTPS_US_ENDPOINT}"
    fi
  fi
else
  if [ "${DD_USE_EU}" = true ]; then
    DEFAULT_LOGS_ENDPOINT="${DD_DEFAULT_TCP_EU_ENDPOINT}"
  else
    DEFAULT_LOGS_ENDPOINT="${DD_DEFAULT_TCP_US_ENDPOINT}"
  fi
fi

if [ -z "${DD_LOGS_CONFIG_LOGS_DD_URL}" ]; then
  # Initialize to default value based on the following order:
  # 1) If both the host/port for logs is specified, use that
  # 2) If the DD_PROXY_HTTPS is set, use that
  # 3) If DD_SITE is set to datadoghq.eu, use default EU host/port
  # 4) Default back to US logs host/port combo.
  if [ -n "${DD_LOGS_CONFIG_DD_PORT}" ] && [ -n "${DD_LOGS_CONFIG_DD_URL}" ]; then
    DD_LOGS_CONFIG_LOGS_DD_URL="${DD_LOGS_CONFIG_DD_URL}:${DD_LOGS_CONFIG_DD_PORT}"
  else
    DD_LOGS_CONFIG_LOGS_DD_URL="${DEFAULT_LOGS_ENDPOINT}"
  fi
fi

if [ "${DD_LOGS_ENABLED}" = "true" ] && [ -n "${DD_LOGS_CONFIG_LOGS_DD_URL}" ] && [ "${DD_SKIP_LOGS_TEST}" != "true" ]; then
  echo "Validating log endpoint ${DD_LOGS_CONFIG_LOGS_DD_URL}"
  LOGS_ENDPOINT=$(echo "${DD_LOGS_CONFIG_LOGS_DD_URL}" | cut -d ":" -f1)
  LOGS_PORT=$(echo "${DD_LOGS_CONFIG_LOGS_DD_URL}" | cut -d ":" -f2)

  # Try establishing tcp connection to logs endpoint with 5s timeout
  # Check out exit code and export a variable for subsequent scripts to use
  if ! nc -w5 "${LOGS_ENDPOINT}" "${LOGS_PORT}" < /dev/null; then
    export DD_LOGS_VALID_ENDPOINT="false"
    echo "Could not establish a connection to ${DD_LOGS_CONFIG_LOGS_DD_URL}."
    # Post alert to datadog
    HTTP_PROXY=${DD_PROXY_HTTP_VAR} HTTPS_PROXY=${DD_PROXY_HTTPS_VAR} NO_PROXY=${DD_NO_PROXY} curl \
      -X POST -H "Content-type: application/json" \
      -d "{
            \"title\": \"Log endpoint cannot be reached - Log collection not started\",
            \"text\": \"Could not establish a connection to ${DD_LOGS_CONFIG_LOGS_DD_URL} after 5 seconds. Log collection has not been started.\",
            \"priority\": \"normal\",
            \"tags\": $(ruby "${DATADOG_DIR}"/scripts/get_tags.rb),
            \"alert_type\": \"error\"
      }" "${DD_API_SITE}v1/events?api_key=${DD_API_KEY}"
  else
    export DD_LOGS_VALID_ENDPOINT="true"
  fi
else
  echo "Skipping log endpoint validation"
fi
