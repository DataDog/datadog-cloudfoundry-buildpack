#!/usr/bin/env bash

# Start dogstatsd

DATADOG_DIR="/home/vcap/app/datadog"

start_datadog() {
  pushd $DATADOG_DIR
    export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
    export DD_API_KEY
    export DD_DD_URL=https://app.datadoghq.com
    datadog_tags=$(python $DATADOG_DIR/scripts/get_tags.py)
    sed -i "s/# tags:.*/tags: $datadog_tags/" $DATADOG_DIR/dist/datadog.yaml
    sed -i "s/# tags:.*/tags: $datadog_tags/" $DATADOG_DIR/dist/datadog.conf
    # Override user set tags so the tags set in the yaml file are used instead
    export DD_TAGS=""
    ./dogstatsd start --cfgpath $DATADOG_DIR/dist/datadog.yaml &
    ./trace-agent -config $DATADOG_DIR/dist/datadog.conf &
  popd
}

if [ -z $DD_API_KEY ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"

  start_datadog
fi
