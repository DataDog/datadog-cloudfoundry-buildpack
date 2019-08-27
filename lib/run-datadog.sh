#!/usr/bin/env bash

DATADOG_DIR=${DATADOG_DIR:-"/home/vcap/app/datadog"}

start_datadog() {
  pushd $DATADOG_DIR
    export HOME=${HOME:-/home/vcap}

    echo "Fixing pkg config settings..."
    pushd $DATADOG_DIR/opt/datadog-agent/embedded/lib/pkgconfig/
      OLD_PREFIX="prefix=/opt/datadog-agent/embedded"
      NEW_PREFIX="prefix=$DATADOG_DIR/opt/datadog-agent/embedded"
      for file in $(ls); do
        if [ -f "${file}" -a ! -L "${file}" ]; then
          sed -i "s~${OLD_PREFIX}~${NEW_PREFIX}~" ${file}
        fi
      done
    popd

    source $DATADOG_DIR/scripts/setup.sh

    # Fix datadog.yaml for apm log file since it cannot be set via env vars currently
    echo "apm_config:" >> $DATADOG_DIR/etc/datadog-agent/datadog.yaml
    echo "  log_file: $DATADOG_DIR/trace.log" >> $DATADOG_DIR/etc/datadog-agent/datadog.yaml

    # enable all checks if we want them
    if [ "$DD_ENABLE_CHECKS" = "true" ]; then
      # enable all checks
      cp -r "$DD_CONF_PATH/disabled_confd" "$DD_CONF_PATH/conf.d"
      # copy user defined integration configurations
      cp -r /home/vcap/app/datadog_integrations/* "$DD_CONF_PATH/conf.d"
    fi
    export DD_ADDITIONAL_CHECKSD=${DD_ADDITIONAL_CHECKSD:-"$DATADOG_DIR/etc/datadog-agent/checks.d"}

    # add logs configs
    if [ -n "$LOGS_CONFIG" ]; then
        mkdir -p $LOGS_CONFIG_DIR
        $DD_AGENT_PYTHON $DATADOG_DIR/scripts/create_logs_config.py
    fi

    $DATADOG_DIR/opt/datadog-agent/bin/agent/agent run --cfgpath $DD_CONF_PATH &

    $DATADOG_DIR/opt/datadog-agent/embedded/bin/trace-agent --config $DD_CONF_PATH/datadog.yaml &
  popd
}

if [ -z $DD_API_KEY ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"
  start_datadog
fi
