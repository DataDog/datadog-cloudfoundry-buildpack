#!/bin/sh

# wait for the buildpack scripts to finish
timeout=0
while { ! [ "$(pidof ./agent)" = "" ] && ! [ "$(pidof ./dogstatsd)" = "" ]; } && [ $timeout -lt 120 ]; do
    sleep 1
    timeout=$((timeout+1))
done

# for debugging purposes
echo $DD_NODE_AGENT_TAGS >> /home/vcap/app/.datadog/dd-node-agent-tags.log

/bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
