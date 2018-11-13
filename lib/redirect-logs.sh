#!/usr/bin/env bash

export LOGS_CONFIG
export STD_LOG_COLLECTION_PORT

# redirect forwards all standard inputs to a TCP socket listening on port STD_LOG_COLLECTION_PORT.
redirect() {
  while true; do
    nc localhost $STD_LOG_COLLECTION_PORT || true
  done
}

# setup the redirection from stdout/stderr to the logs-agent.
if [ "$DD_LOGS_ENABLED" = "true" ]; then
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
