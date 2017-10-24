#!/usr/bin/env bash

# Start dogstatsd

DATADOG_DIR="/home/vcap/app/datadog"

get_vcap_var() {
  echo $VCAP_APPLICATION | $DATADOG_DIR/jq -r $@
}

get_tags() {
  local app_id=$(get_vcap_var '.application_id')
  local app_name=$(get_vcap_var '.application_name')
  local instance_index=$(get_vcap_var '.instance_index')
  local space_name=$(get_vcap_var '.space_name')

  tags="application_id:$app_id,application_name:$app_name,instance_index:$instance_index,space_name:$space_name"
  echo $tags
}

start_datadog() {
  pushd $DATADOG_DIR
    local app_id=$(get_vcap_var '.application_id')
    local app_name=$(get_vcap_var '.application_name')
    local instance_index=$(get_vcap_var '.instance_index')
    local space_name=$(get_vcap_var '.space_name')
    export DD_LOG_FILE=$DATADOG_DIR/dogstatsd.log
    export DD_LOG_LEVEL='debug'
    export DD_API_KEY=$DATADOG_API_KEY
    export DD_DD_URL=https://app.datadoghq.com
    datadog_tags="[\"application_id:$app_id\",\"application_name:$app_name\",\"instance_index:$instance_index\",\"space_name:$space_name\"]"
    sed -i "s/# tags:.*/tags: $datadog_tags/" $DATADOG_DIR/dist/datadog.yaml
    echo $DD_TAGS
    ./dogstatsd start --cfgpath $DATADOG_DIR/dist &
  popd
}

if [ -z ${DATADOG_API_KEY+x} ]; then
  echo "Datadog API Key not set, not starting Datadog"
else
  echo "starting datadog"

  start_datadog
fi
