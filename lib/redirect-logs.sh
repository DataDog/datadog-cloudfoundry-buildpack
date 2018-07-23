#!/usr/bin/env bash

export DD_LOGS_CONFIG_TCP_FORWARD_PORT="${DD_LOGS_CONFIG_TCP_FORWARD_PORT:-10514}"
export DISABLE_STD_LOG_COLLECTION="${DISABLE_STD_LOG_COLLECTION:-false}"

redirect() {
  while true; do
    nc localhost $DD_LOGS_CONFIG_TCP_FORWARD_PORT || true
  done
}

if [ "$DD_LOGS_ENABLED" = "true" ]; then
  if [ "$DISABLE_STD_LOG_COLLECTION" != "true" ]; then
    echo "collect all logs forwarded to stdout/stderr"
    exec &> >(tee >(redirect))
  else
    echo "collect all logs forwarded to port $DD_LOGS_CONFIG_TCP_FORWARD_PORT"
  fi
fi
