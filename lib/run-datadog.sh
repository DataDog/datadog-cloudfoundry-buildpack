#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

# Start dogstatsd

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/datadog}"

start_datadog() {
  pushd $DATADOG_DIR
    export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
    export DD_API_KEY
    export DD_DD_URL
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-true}"
    export DOCKER_DD_AGENT=yes
    export LOGS_CONFIG_DIR=$DATADOG_DIR/dist/conf.d/logs.d
    export LOGS_CONFIG

    # Setup .NET Tracing configuration if DD_DOTNET_TRACING is set to true
    if [ "$DD_DOTNET_TRACING" = "true" ]; then
      export DD_TRACE_ENABLED=true
      export CORECLR_ENABLE_PROFILING=1
      export CORECLR_PROFILER="{846F5F1C-F9AE-4B07-969E-05C26BC060D8}"
      export CORECLR_PROFILER_PATH=$DATADOG_DIR/dotnet/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
      export DD_INTEGRATIONS=$DATADOG_DIR/dotnet/opt/datadog/integrations.json
      export DD_DOTNET_TRACER_HOME=$DATADOG_DIR/dotnet/opt/datadog/
      export DD_TRACE_LOG_PATH=$DATADOG_DIR/dotnet/dotnet.log
    fi

    # create and configure set /conf.d if integrations are enabled
    if [ "$DD_ENABLE_CHECKS" = "true" ] || [ -n "$LOGS_CONFIG" ] ; then
      mkdir $DATADOG_DIR/dist/conf.d
      sed -i "s~# confd_path:.*~confd_path: $DATADOG_DIR/dist/conf.d~" $DATADOG_DIR/dist/datadog.yaml
    fi

    # add checks configs
    if [ "$DD_ENABLE_CHECKS" = "true" ]; then
      mv $DATADOG_DIR/conf.d/* $DATADOG_DIR/dist/conf.d
    fi

    # add logs configs
    if [ -n "$LOGS_CONFIG" ]; then
      mkdir -p $LOGS_CONFIG_DIR
      python $DATADOG_DIR/scripts/create_logs_config.py
    fi

    # The yaml file requires the tags to be an array,
    # the conf file requires them to be comma separated only
    # so they must be grabbed separately
    datadog_tags=$(python $DATADOG_DIR/scripts/get_tags.py)
    sed -i "s~# tags:.*~tags: $datadog_tags~" $DATADOG_DIR/dist/datadog.yaml
    sed -i "s~log_file: TRACE_LOG_FILE~log_file: $DATADOG_DIR/trace.log~" $DATADOG_DIR/dist/datadog.yaml
    if [ -n "$DD_SKIP_SSL_VALIDATION" ]; then
      sed -i "s~# skip_ssl_validation: no~skip_ssl_validation: yes~" $DATADOG_DIR/dist/datadog.yaml
    fi
    # Override user set tags so the tags set in the yaml file are used instead
    export DD_TAGS=""

    if [ -n "$DD_HTTP_PROXY" ]; then
      sed -i "s~# proxy:~proxy:~" $DATADOG_DIR/dist/datadog.yaml
      sed -i "s~#   http: HTTP_PROXY~  http: $DD_HTTP_PROXY~" $DATADOG_DIR/dist/datadog.yaml
    else
      if [ -n "$HTTP_PROXY" ]; then
        sed -i "s~# proxy:~proxy:~" $DATADOG_DIR/dist/datadog.yaml
        sed -i "s~#   http: HTTP_PROXY~  http: $HTTP_PROXY~" $DATADOG_DIR/dist/datadog.yaml
      fi
    fi
    if [ -n "$DD_HTTPS_PROXY" ]; then
      sed -i "s~# proxy:~proxy:~" $DATADOG_DIR/dist/datadog.yaml
      sed -i "s~#   https: HTTPS_PROXY~  https: $DD_HTTPS_PROXY~" $DATADOG_DIR/dist/datadog.yaml
    else
      if [ -n "$HTTPS_PROXY" ]; then
        sed -i "s~# proxy:~proxy:~" $DATADOG_DIR/dist/datadog.yaml
        sed -i "s~#   https: HTTPS_PROXY~  https: $HTTPS_PROXY~" $DATADOG_DIR/dist/datadog.yaml
      fi
    fi

    #Override default EXPVAR Port
    if [ -n "$DD_EXPVAR_PORT" ]; then
      sed -i "s~# expvar_port: 5000~expvar_port: $DD_EXPVAR_PORT~" $DATADOG_DIR/dist/datadog.yaml
    fi
    #Override default CMD Port
    if [ -n "$DD_CMD_PORT" ]; then
      sed -i "s~# cmd_port: 5001~cmd_port: $DD_CMD_PORT~" $DATADOG_DIR/dist/datadog.yaml
    fi

    # DSD requires its own config file
    cp $DATADOG_DIR/dist/datadog.yaml $DATADOG_DIR/dist/dogstatsd.yaml
    if [ -n "$RUN_AGENT" -a -f ./puppy ]; then
      if [ "$DD_LOGS_ENABLED" = "true" -a "$DD_LOGS_VALID_ENDPOINT" = "false" ]; then
        echo "Log endpoint not valid, not starting agent"
      else
        export DD_LOG_FILE=$DATADOG_DIR/agent.log
        sed -i "s~log_file: AGENT_LOG_FILE~log_file: $DD_LOG_FILE~" $DATADOG_DIR/dist/datadog.yaml
        ./puppy run --cfgpath $DATADOG_DIR/dist/ &
      fi
    else
      export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
      sed -i "s~log_file: AGENT_LOG_FILE~log_file: $DD_LOG_FILE~" $DATADOG_DIR/dist/datadog.yaml
      ./dogstatsd start --cfgpath $DATADOG_DIR/dist/ &
    fi
    ./trace-agent --config $DATADOG_DIR/dist/datadog.yaml &
  popd
}

if [ -z $DD_API_KEY ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"
  start_datadog
fi
