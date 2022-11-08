# wait for agent startup

timeout=0
while ! [ -f /home/vcap/app/.datadog/run/agent.pid ] && [ $timeout -lt 120 ]; do
    sleep 0.5
    timeout=$((timeout+1))
done


/bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
