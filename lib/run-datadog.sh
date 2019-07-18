#!/usr/bin/env bash

# Start dogstatsd

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/datadog}"

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

    # Setup LD_LIBRARY_PATH
    LD_LIBRARY_PATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib:$LD_LIBRARY_PATH"
    for package_lib_dir in $(ls -d $DATADOG_DIR/opt/datadog-agent/embedded/lib 2>/dev/null); do
        LD_LIBRARY_PATH="$package_lib_dir:$LD_LIBRARY_PATH"
    done
    for package_lib_dir in $(ls -d $DATADOG_DIR/opt/datadog-agent/embedded/lib/python*/lib-dynload 2>/dev/null); do
        LD_LIBRARY_PATH="$package_lib_dir:$LD_LIBRARY_PATH"
    done
    for package_lib_dir in $(ls -d $DATADOG_DIR/opt/datadog-agent/embedded/lib/python*/site-packages 2>/dev/null); do
        LD_LIBRARY_PATH="$package_lib_dir:$LD_LIBRARY_PATH"
    done

    # configure confd and checksd
    export DD_CONFD_PATH=${DD_CONFD_PATH:-"$DATADOG_DIR/etc/datadog-agent/conf.d"}
  	export DD_ADDITIONAL_CHECKSD=${DD_ADDITIONAL_CHECKSD:-"$DATADOG_DIR/etc/datadog-agent/checks.d"}

    # Setup PYTHONPATH and PYTHONHOME
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7:$PYTHONPATH"
    for python_mod_dir in $(ls -d $DATADOG_DIR/opt/datadog-agent/embedded/lib/python*/site-packages 2>/dev/null); do
        PYTHONPATH="$python_mod_dir:$PYTHONPATH"
    done
    PYTHONPATH="$DD_ADDITIONAL_CHECKSD:$PYTHONPATH"
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python27.zip:$PYTHONPATH"
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7:$PYTHONPATH"
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7/plat-linux2:$PYTHONPATH"
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7/lib-tk:$PYTHONPATH"
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7/lib-old:$PYTHONPATH"
    PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python2.7/lib-dynload:$PYTHONPATH"
    export PYTHONPATH
    export PYTHONHOME="$DATADOG_DIR/opt/datadog-agent/embedded/"
    export DD_AGENT_PYTHON="$DATADOG_DIR/opt/datadog-agent/embedded/bin/python"

    export DD_API_KEY
    export DD_DD_URL=${DD_DD_URL:-"https://app.datadoghq.com"}
    export DD_ENABLE_CHECKS=${DD_ENABLE_CHECKS:-true}
    export LOGS_CONFIG_DIR=$DATADOG_DIR/etc/datadog-agent/conf.d/logs.d
    export LOGS_CONFIG
    export DD_LOGS_CONFIG_RUN_PATH=${DD_LOGS_CONFIG_RUN_PATH:-"$DATADOG_DIR/opt/datadog-agent/run"}

    # add logs configs
    if [ -n "$LOGS_CONFIG" ]; then
      mkdir -p $LOGS_CONFIG_DIR
      python $DATADOG_DIR/scripts/create_logs_config.py
    fi

    export DD_TAGS=$(python $DATADOG_DIR/scripts/get_tags.py)
    export DD_APM_CONFIG_LOG_FILE=${DD_APM_CONFIG_LOG_FILE:-"$DATADOG_DIR/trace.log"}
    export DD_LOG_FILE=${DD_LOG_FILE:-"$DATADOG_DIR/agent.log"}

    LD_LIBRARY_PATH=$LD_LIBRARY_PATH $DATADOG_DIR/opt/datadog-agent/bin/agent/agent run --cfgpath $DATADOG_DIR/etc/datadog-agent/ &
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH $DATADOG_DIR/opt/datadog-agent/embedded/bin/trace-agent --config $DATADOG_DIR/etc/datadog-agent/datadog.yaml &
  popd
}

if [ -z $DD_API_KEY ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"
  start_datadog
fi
