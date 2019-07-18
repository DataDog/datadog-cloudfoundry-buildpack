#!/usr/bin/env bash

DATADOG_DIR=${DATADOG_DIR:-"/home/vcap/app/datadog"}

export DD_API_KEY
export DD_DD_URL=${DD_DD_URL:-"https://app.datadoghq.com"}
export DD_ENABLE_CHECKS=${DD_ENABLE_CHECKS:-"false"}
export DD_CONF_PATH=${DD_CONF_PATH:-"$DATADOG_DIR/etc/datadog-agent"}
export DD_CONFD_PATH="$DATADOG_DIR/etc/datadog-agent/conf.d"
export LOGS_CONFIG_DIR="$DATADOG_DIR/etc/datadog-agent/conf.d/logs.d"
export LOGS_CONFIG
export DD_LOGS_CONFIG_RUN_PATH=${DD_LOGS_CONFIG_RUN_PATH:-"$DATADOG_DIR/opt/datadog-agent/run"}
export DD_PYTHON_VERSION=3

# Setup LD_LIBRARY_PATH
LD_LIBRARY_PATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib:$LD_LIBRARY_PATH"
LD_LIBRARY_PATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python3.7/lib-dynload:$LD_LIBRARY_PATH"
LD_LIBRARY_PATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python3.7/site-packages:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH

# Setup PYTHONPATH and PYTHONHOME
PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python3.7:$PYTHONPATH"
PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python3.7/site-packages:$PYTHONPATH"
PYTHONPATH="$DD_ADDITIONAL_CHECKSD:$PYTHONPATH"
PYTHONPATH="$DATADOG_DIR/opt/datadog-agent/embedded/lib/python3.7/lib-dynload:$PYTHONPATH"
export PYTHONPATH
export PYTHONHOME="$DATADOG_DIR/opt/datadog-agent/embedded/"
export DD_AGENT_PYTHON="$DATADOG_DIR/opt/datadog-agent/embedded/bin/python3"

export DD_TAGS=$($DD_AGENT_PYTHON $DATADOG_DIR/scripts/get_tags.py)
export DD_APM_CONFIG_LOG_FILE=${DD_APM_CONFIG_LOG_FILE:-"$DATADOG_DIR/trace.log"}
export DD_LOG_FILE=${DD_LOG_FILE:-"$DATADOG_DIR/agent.log"}
