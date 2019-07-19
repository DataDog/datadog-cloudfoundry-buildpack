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

    echo "Fixing python prefixes..."
    pushd $DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7/
      echo "import site" >> sitecustomize.py
      echo "site.addsitedir('$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7/site-packages')" >> sitecustomize.py
      echo "site.PREFIXES.append('$DATADOG_DIR/opt/datadog-agent/embedded/')" >> sitecustomize.py
    popd

    source $DATADOG_DIR/scripts/setup.sh

    # Fix datadog.yaml for apm log file since it cannot be set via env vars currently
    echo "apm_config:" >> $DD_CONF_PATH/datadog.yaml
    echo "  log_file: $DATADOG_DIR/trace.log" >> $DD_CONF_PATH/datadog.yaml

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
