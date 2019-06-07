#!/usr/bin/env bash

unset DD_LOGS_VALID_ENDPOINT
DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/datadog}"

if [ "$DD_LOGS_VALIDATE_ENDPOINT" = "true" ]; then
  echo "Validating endpoint $DD_LOGS_CONFIG_LOGS_DD_URL"
  LOGS_ENDPOINT=`echo $DD_LOGS_CONFIG_LOGS_DD_URL | cut -d ":" -f1`
  LOGS_PORT=`echo $DD_LOGS_CONFIG_LOGS_DD_URL | cut -d ":" -f2`

  # Try establishing tcp connection to logs endpoint with 5s timeout
  nc -w5 -N $LOGS_ENDPOINT $LOGS_PORT < /dev/null

  # Check out exit code and export a variable for subsequent scripts to use
  if [ $? -ne 0 ]; then
    export DD_LOGS_VALID_ENDPOINT="false"
    echo "Could not establish a TCP connection to $DD_LOGS_CONFIG_LOGS_DD_URL after 5 seconds."
    # Post alert to datadog
    HTTP_PROXY=$DD_HTTP_PROXY HTTPS_PROXY=$DD_HTTPS_PROXY NO_PROXY=$DD_NO_PROXY curl \
      -X POST -H "Content-type: application/json" \
      -d "{
            \"title\": \"Log endpoint cannot be reached - Log collection not started\",
            \"text\": \"Could not establish a TCP connection to $DD_LOGS_CONFIG_LOGS_DD_URL after 5 seconds. Log collection has not been started.\",
            \"priority\": \"normal\",
            \"tags\": $(python $DATADOG_DIR/scripts/get_tags.py),
            \"alert_type\": \"error\"
      }" "https://api.datadoghq.com/api/v1/events?api_key=$DD_API_KEY"
  else
    export DD_LOGS_VALID_ENDPOINT="true"
  fi
fi
