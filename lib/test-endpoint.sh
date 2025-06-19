#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
DD_SKIP_LOGS_VALIDATION=${DD_SKIP_LOGS_VALIDATION:true}

# source updated PATH
. "$DATADOG_DIR/.global_env"

if [ "${DD_SKIP_LOGS_VALIDATION}" == "true"]; then
  echo "Skipping log endpoint validation: DD_SKIP_LOGS_VALIDATION is set to true."
  return
fi

unset DD_LOGS_VALID_ENDPOINT
DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

# Sets variable in order of DD_PROXY_HTTP -> DD_HTTP_PROXY -> HTTP_PROXY
DD_PROXY_HTTP_VAR=${DD_PROXY_HTTP:-${DD_HTTP_PROXY}}
DD_PROXY_HTTP_VAR=${DD_PROXY_HTTP_VAR:-${HTTP_PROXY}}

# Sets variable in order of DD_PROXY_HTTPS -> DD_HTTPS_PROXY -> HTTPS_PROXY
DD_PROXY_HTTPS_VAR=${DD_PROXY_HTTPS:-${DD_HTTPS_PROXY}}
DD_PROXY_HTTPS_VAR=${DD_PROXY_HTTPS_VAR:-${HTTPS_PROXY}}

DD_STRIPPED_PROXY_HTTPS="${DD_PROXY_HTTPS_VAR//https:\/\/}"
DD_STRIPPED_PROXY_HTTPS="${DD_STRIPPED_PROXY_HTTPS//http:\/\/}"

# Default endpoints can be found in DD Docs - https://docs.datadoghq.com/agent/logs/
DD_DEFAULT_HTTPS_ENDPOINT="agent-http-intake.logs.${DD_SITE}:443"
DD_DEFAULT_TCP_ENDPOINT="agent-intake.logs.${DD_SITE}:443" # only supported in US1 and EU

if [ "${DD_LOGS_CONFIG_USE_HTTP}" = true ]; then
  if [ -n "${DD_STRIPPED_PROXY_HTTPS}" ]; then
    DEFAULT_LOGS_ENDPOINT="${DD_STRIPPED_PROXY_HTTPS}"
  else
    DEFAULT_LOGS_ENDPOINT="${DD_DEFAULT_HTTPS_US_ENDPOINT}"
  fi
else
    DEFAULT_LOGS_ENDPOINT="${DD_DEFAULT_TCP_EU_ENDPOINT}"
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
      }" "api.${DD_SITE}/v1/events?api_key=${DD_API_KEY}"
  else
    export DD_LOGS_VALID_ENDPOINT="true"
  fi
else
  echo "Skipping log endpoint validation"
fi
