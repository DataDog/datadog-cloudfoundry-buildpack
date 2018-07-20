#!/usr/bin/env bash

if [ "$DD_LOGS_ENABLED" = "true" -a "$COLLECT_FROM_STD" != "false" ]; then
  echo "starting std-log-forwarding"  
  exec &> >(tee >(nc localhost $DD_LOGS_CONFIG_TCP_FORWARD_PORT))
fi
