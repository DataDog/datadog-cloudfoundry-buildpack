# wait for agent startup
while ! [ -f /home/vcap/app/.datadog/run/agent.pid ]; do
    sleep 0.5
done


/bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
