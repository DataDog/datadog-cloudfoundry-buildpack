#!/usr/bin/env bash

# Start dogstatsd

DATADOG_DIR="/home/vcap/app/datadog"

start_datadog() {
  pushd $DATADOG_DIR
    export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
    export DD_API_KEY
    export DD_DD_URL=https://app.datadoghq.com
    export DD_ENABLE_CHECKS="${DD_ENABLE_CHECKS:-true}"
    export DOCKER_DD_AGENT=yes

    if [ "$DD_ENABLE_CHECKS" = "true" ]; then
      sed -i "s~# confd_path:.*~confd_path: $DATADOG_DIR/conf.d~" $DATADOG_DIR/dist/datadog.yaml
    fi

    # The yaml file requires the tags to be an array,
    # the conf file requires them to be comma separated only
    # so they must be grabbed separately
    datadog_tags=$(python $DATADOG_DIR/scripts/get_tags.py)
    sed -i "s/# tags:.*/tags: $datadog_tags/" $DATADOG_DIR/dist/datadog.yaml
    legacy_datadog_tags=$(LEGACY_TAGS_FORMAT=true python $DATADOG_DIR/scripts/get_tags.py)
    sed -i "s/# tags:.*/tags: $legacy_datadog_tags/" $DATADOG_DIR/dist/datadog.conf
    sed -i "s~# log_file: TRACE_LOG_FILE~log_file: $DATADOG_DIR/trace.log~" $DATADOG_DIR/dist/datadog.conf
    # Override user set tags so the tags set in the yaml file are used instead
    export DD_TAGS=""

    # DSD requires its own config file
    cp $DATADOG_DIR/dist/datadog.yaml $DATADOG_DIR/dist/dogstatsd.yaml
    if [ -n "$RUN_AGENT" -a -f ./puppy ]; then
      export DD_LOG_FILE=$DATADOG_DIR/agent.log
      ./puppy start --cfgpath $DATADOG_DIR/dist/ &
    else
      export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
      ./dogstatsd start --cfgpath $DATADOG_DIR/dist/ &
    fi
    ./trace-agent -ddconfig $DATADOG_DIR/dist/datadog.conf &
  popd
}

if [ -z $DD_API_KEY ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"

  start_datadog
fi
