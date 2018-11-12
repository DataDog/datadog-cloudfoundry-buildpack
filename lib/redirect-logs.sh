#!/usr/bin/env bash

export DD_LOGS_ENABLED="${DD_LOGS_ENABLED:-false}"
export DISABLE_STD_LOG_COLLECTION="${DISABLE_STD_LOG_COLLECTION:-false}"
export DD_LOGS_CONFIG_CUSTOM_CONFIG
export STD_LOG_COLLECTION_PORT

# redirect forwards all standard inputs to a TCP socket listening on port STD_LOG_COLLECTION_PORT.
redirect() {
  while true; do
    nc localhost $STD_LOG_COLLECTION_PORT || true
  done
}

# setup the redirection from stdout/stderr to the logs-agent.
if [ "$DD_LOGS_ENABLED" = "true" ]; then
  if [ -z "DD_LOGS_CONFIG_CUSTOM_CONFIG" ]
    echo "can't collect logs, DD_LOGS_CONFIG_CUSTOM_CONFIG is not set"
  else
    echo "collect all logs for config $DD_LOGS_CONFIG_CUSTOM_CONFIG"
    if [ "$DISABLE_STD_LOG_COLLECTION" != "true" ]; then
      if [ -z "$STD_LOG_COLLECTION_PORT" ]; then
        echo "can't collect logs on stdout/stderr, STD_LOG_COLLECTION_PORT is not set"
      else
        echo "forward all logs from stdout/stderr to agent port $STD_LOG_COLLECTION_PORT"
        exec &> >(tee >(redirect))
      fi
    fi
  fi
fi
