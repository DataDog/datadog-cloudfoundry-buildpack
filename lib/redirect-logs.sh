#!/usr/bin/env bash

redirect() {
  while true; do
    nc localhost $DD_LOGS_CONFIG_TCP_FORWARD_PORT
  done
}

if [ "$DD_LOGS_ENABLED" = "true" -a "$COLLECT_FROM_STD" != "false" ]; then
  exec &> >(tee >(redirect))
fi
