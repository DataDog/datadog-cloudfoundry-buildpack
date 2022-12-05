#!/bin/sh

# wait for the buildpack scripts to finish
DEBUG_FILE="/home/vcap/app/.datadog/update_agent_config_out.log"

main() {
    echo "Starting to wait for agent process to start"
    timeout=0

    while [ $timeout -lt 120 ]; do
        echo "Waiting for agent process to start"

        if pgrep -f ./agent; then
            echo "Found agent process"
            break
        fi

        if pgrep -f ./dogstatsd; then
            echo "Found dogstatsd process"
            break
        fi
        sleep 1
        timeout=$((timeout+1))
    done
    echo "$DD_NODE_AGENT_TAGS"

    /bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
}
# for debugging purposes
main "$@" >> "$DEBUG_FILE" 2>&1
