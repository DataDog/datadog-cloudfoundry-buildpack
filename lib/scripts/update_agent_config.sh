#!/bin/sh

# wait for the buildpack scripts to finish
timeout=0
while ! [ -f /home/vcap/app/.datadog/run/agent.pid ] && [ $timeout -lt 120 ]; do
    sleep 1
    timeout=$((timeout+1))
done

# for debugging purposes
echo $DD_NODE_AGENT_TAGS > /home/vcap/app/.datadog/dd-node-agent-tags.log

/bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
