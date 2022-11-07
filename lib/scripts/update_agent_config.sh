
echo "script was called" >> /tmp/script-called.txt


# wait for agent startup
while ! [ -f /home/vcap/app/.datadog/run/agent.pid ]; do
    sleep 0.5
done


echo "MAIN script is run" >> /home/vcap/app/.datadog/main-script.log
/bin/bash /home/vcap/app/.datadog/scripts/update_agent_config_restart.sh
echo "MAIN script is finished" >> /home/vcap/app/.datadog/main-script.log
