#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

export LOGS_CONFIG
export STD_LOG_COLLECTION_PORT

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"

DD_EU_API_SITE="https://api.datadoghq.eu/api/"
DD_US_API_SITE="https://api.datadoghq.com/api/"
DD_API_SITE=$DD_US_API_SITE

if [ -n "$DD_SITE" ] && [ "$DD_SITE" = "datadoghq.eu" ]; then
  DD_API_SITE=$DD_EU_API_SITE
fi

# redirect forwards all standard inputs to a TCP socket listening on port STD_LOG_COLLECTION_PORT.
redirect() {
  while kill -0 $$; do
    nc localhost $STD_LOG_COLLECTION_PORT || sleep 0.5
    echo "Resetting buildpack log redirection"
    if [ "$DD_DEBUG_STD_REDIRECTION" = "true" ]; then
      HTTP_PROXY=$DD_HTTP_PROXY HTTPS_PROXY=$DD_HTTPS_PROXY NO_PROXY=$DD_NO_PROXY curl \
      -X POST -H "Content-type: application/json" \
      -d "{
            \"title\": \"Resetting buildpack log redirection\",
            \"text\": \"TCP socket on port $STD_LOG_COLLECTION_PORT for log redirection closed. Restarting it.\",
            \"priority\": \"normal\",
            \"tags\": $(python $DATADOG_DIR/scripts/get_tags.py),
            \"alert_type\": \"info\"
      }" "${DD_API_SITE}v1/events?api_key=$DD_API_KEY"
    fi
  done
}

# setup the redirection from stdout/stderr to the logs-agent.
if [ "$DD_LOGS_ENABLED" = "true" ]; then
  if [ "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
    echo "Log endpoint not valid, not starting log redirection"
  else
    if [ -z "$LOGS_CONFIG" ]; then
      echo "can't collect logs, LOGS_CONFIG is not set"
    else
      echo "collect all logs for config $LOGS_CONFIG"
      if [ -n "$STD_LOG_COLLECTION_PORT" ]; then
        echo "forward all logs from stdout/stderr to agent port $STD_LOG_COLLECTION_PORT"
        exec &> >(tee >(redirect))
      fi
    fi
  fi
fi
