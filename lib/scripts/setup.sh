#!/usr/bin/env bash

DATADOG_DIR=${DATADOG_DIR:-"/home/vcap/app/datadog"}

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
export LD_LIBRARY_PATH

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

export DD_TAGS=$(python $DATADOG_DIR/scripts/get_tags.py)
export DD_APM_CONFIG_LOG_FILE=${DD_APM_CONFIG_LOG_FILE:-"$DATADOG_DIR/trace.log"}
export DD_LOG_FILE=${DD_LOG_FILE:-"$DATADOG_DIR/agent.log"}

export DD_CONF_PATH=${DD_CONF_PATH:-"$DATADOG_DIR/etc/datadog-agent"}
