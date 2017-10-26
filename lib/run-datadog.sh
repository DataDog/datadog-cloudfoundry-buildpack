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
    ./dogstatsd start --cfgpath $DATADOG_DIR/dist/datadog.yaml &
  popd
}

if [ -z $DD_API_KEY ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"

  start_datadog
fi
