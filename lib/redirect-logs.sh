#!/usr/bin/env bash

redirect() {
  while true; do
    nc localhost $DD_LOGS_CONFIG_TCP_FORWARD_PORT || true
  done
}

if [ "$DD_LOGS_ENABLED" = "true" ]; then
  if [ -n "$DD_LOGS_CONFIG_TCP_FORWARD_PORT" ]; then
    if [ "$COLLECT_FROM_STD" != "false" ]; then
      echo "collect all logs forwarded on stdout/stderr"
      exec &> >(tee >(redirect))
    else
      echo "collect all logs forwarded on port $DD_LOGS_CONFIG_TCP_FORWARD_PORT"
    fi
  else
    echo "TCP forward port is not set, can't collect logs."
  fi
fi
