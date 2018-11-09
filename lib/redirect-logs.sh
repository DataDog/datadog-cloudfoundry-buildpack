#!/usr/bin/env bash

export DD_LOGS_ENABLED="${DD_LOGS_ENABLED:-false}"
export DISABLE_STD_LOG_COLLECTION="${DISABLE_STD_LOG_COLLECTION:-false}"
export DD_LOGS_CONFIG_CUSTOM_CONFIG
export DD_LOGS_CONFIG_TCP_FORWARD_PORT

# redirect forwards all standard inputs to a TCP socket listening on port DD_LOGS_CONFIG_TCP_FORWARD_PORT.
redirect() {
  while true; do
    nc localhost $DD_LOGS_CONFIG_TCP_FORWARD_PORT || true
  done
}

# setup the redirection from stdout/stderr to the logs-agent.
if [ "$DD_LOGS_ENABLED" = "true" ]; then
  if [ -z "$DD_LOGS_CONFIG_TCP_FORWARD_PORT" ]; then
    echo "can't collect logs, DD_LOGS_CONFIG_TCP_FORWARD_PORT is not set"
  elif [ -z "DD_LOGS_CONFIG_CUSTOM_CONFIG" ]
    echo "can't collect logs, DD_LOGS_CONFIG_CUSTOM_CONFIG is not set"
  else
    echo "collect all logs for config $DD_LOGS_CONFIG_CUSTOM_CONFIG"
    if [ "$DISABLE_STD_LOG_COLLECTION" != "true" ]; then
      echo "forward all logs from stdout/stderr to agent port $DD_LOGS_CONFIG_TCP_FORWARD_PORT"
      exec &> >(tee >(redirect))
    fi
  fi
fi
