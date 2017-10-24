#!/usr/bin/env bash

# Start dogstatsd

DATADOG_DIR="/home/vcap/app/datadog"

if [ -z ${DATADOG_API_KEY+x} ]; then
  echo "Datadog API Key not set, not starting Datadog"
  exit 0
fi

echo "starting datadog"

pushd $DATADOG_DIR
  DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log DD_API_KEY=$DATADOG_API_KEY DD_DD_URL=https://app.datadoghq.com ./dogstatsd start &
popd
