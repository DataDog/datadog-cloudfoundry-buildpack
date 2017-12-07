#!/usr/bin/env bash

echo "This script will install the latest buildpack version"

if command -v curl  > /dev/null 2>&1; then
    export DOWNLOADER="curl -k -L -o"
    export HTTP_TESTER="curl -f"
    export GETTER="curl -k -L"
elif command -v wget  > /dev/null 2>&1; then
    export DOWNLOADER="wget -O"
    export HTTP_TESTER="wget -O /dev/null"
    export GETTER="wget -q -O -"
fi

if ! command -v cf > /dev/null 2>&1; then
  echo "You need the cf cli tool to install the buildpacks"
fi

meta_buildpack_name="meta_buildpack"

if [[ ! $(cf buildpacks 2>&1 | grep "meta_buildpack" 2>/dev/null) ]]; then
  echo "Cannot detect the meta buildpack, installing it"
  if [ ! -d "/tmp/datadog-buildpack/" ]; then
    mkdir /tmp/datadog-buildpack/
  fi

  url="https://api.github.com/repos/cf-platform-eng/meta-buildpack/releases/latest"
  if [ -z "$GITHUB_TOKEN" ]; then
    url=$url"?access_token="$GITHUB_TOKEN
  fi
  export meta_buildpack_repo_data=`$GETTER $url`

  meta_buildpack_url=$(python - <<END
import json
import os

data = os.environ['meta_buildpack_repo_data']

try:
  repo_data = json.loads(data)
  for asset in repo_data.get("assets", []):
    if asset.get("name", "").endswith(".tgz"):
      print asset.get("url")
except:
  print "ACCESS ERROR"
END
)

  meta_buildpack_package_name=$(python - <<END
import json
import os

data = os.environ['meta_buildpack_repo_data']

try:
  repo_data = json.loads(data)
  for asset in repo_data.get("assets", []):
    if asset.get("name", "").endswith(".tgz"):
      print asset.get("name")
except:
  print "ACCESS ERROR"
END
)

  if [ "$meta_buildpack_url" == "ACCESS ERROR" ]; then
    echo "Error accessing the github api. You're probably rate limited. Try adding an access token to the GITHUB_TOKEN environment variable."
  fi

  echo "Downloading the meta buildpack"

  $DOWNLOADER "/tmp/datadog-buildpack/$meta_buildpack_package_name" $meta_buildpack_url

  echo "Uploading the meta buildpack"

  cf create-buildpack "meta_buildpack" "/tmp/datadog-buildpack/$meta_buildpack_package_name" 1 --enable
fi


url="https://api.github.com/repos/DataDog/datadog-cloudfoundry-buildpack/releases/latest"
if [ -z "$GITHUB_TOKEN" ]; then
  url=$url"?access_token="$GITHUB_TOKEN
fi
export dd_repo_data=`$GETTER $url`

dd_buildpack_url=$(python - <<END
import json
import os

data = os.environ['dd_repo_data']

try:
repo_data = json.loads(data)
  for asset in repo_data.get("assets", []):
    if asset.get("name", "").endswith(".tgz"):
      print asset.get("url")
except:
  print "ACCESS ERROR"
END
)

dd_package_name=$(python - <<END
import json
import os

data = os.environ['dd_repo_data']

try:
repo_data = json.loads(data)
  for asset in repo_data.get("assets", []):
    if asset.get("name", "").endswith(".tgz"):
      print asset.get("name")
except:
  print "ACCESS ERROR"
END
)

echo "Downloading the datadog buildpack"

$DOWNLOADER "/tmp/datadog-buildpack/$dd_package_name" $metaddbuildpack_url

echo "Uploading the datadog buildpack"

cf create-buildpack "datadog-cloudfoundry-buildpack" "/tmp/datadog-buildpack/$dd_package_name" 99 --enable

rm -rf /tmp/datadog-buildpack/
