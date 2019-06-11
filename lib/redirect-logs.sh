#!/usr/bin/env bash

export LOGS_CONFIG
export STD_LOG_COLLECTION_PORT

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/datadog}"

# redirect forwards all standard inputs to a TCP socket listening on port STD_LOG_COLLECTION_PORT.
redirect() {
  while true; do
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
      }" "https://api.datadoghq.com/api/v1/events?api_key=$DD_API_KEY"
    fi
  done
}

# setup the redirection from stdout/stderr to the logs-agent.
if [ "$DD_LOGS_ENABLED" = "true" ]; then
  if [ "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
    echo "Log endpoint not valid, not starting log redirection"
  else
    if [ -z "LOGS_CONFIG" ]; then
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
