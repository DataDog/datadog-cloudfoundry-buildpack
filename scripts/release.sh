#!/bin/bash -l

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail

# Make sure variables are set
PRODUCTION=${PRODUCTION:-"false"}
STAGING=${STAGING:-"false"}
DRY_RUN=${DRY_RUN:-"true"}
RELEASE_BUCKET=${RELEASE_BUCKET:-"false"}
REPO_BRANCH=${REPO_BRANCH:-"master"}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

git checkout $REPO_BRANCH

# run the prepare script
REFRESH_ASSETS=1 ./scripts/prepare.sh

# build the buildpack
./scripts/build.sh

if [ "$DRY_RUN" == "true" ]; then
  exit 0
fi

VERSION=$(cat VERSION)

echo "publishing the buildpack artifact"

if [ "$RELEASE_BUCKET" -a "$RELEASE_BUCKET" != "false" ]; then
  if [ "$PRODUCTION" = "true" ]; then
    # the production release bucket is cloudfoundry.datadoghq.com/datadog-cloudfoundry-buildpack
    aws s3 cp datadog-cloudfoundry-buildpack-$VERSION.zip s3://$RELEASE_BUCKET/datadog-cloudfoundry-buildpack-$VERSION.zip --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers full=id=3a6e02b08553fd157ae3fb918945dd1eaae5a1aa818940381ef07a430cf25732

    aws s3 cp datadog-cloudfoundry-buildpack-$VERSION.zip s3://$RELEASE_BUCKET/datadog-cloudfoundry-buildpack-latest.zip --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers full=id=3a6e02b08553fd157ae3fb918945dd1eaae5a1aa818940381ef07a430cf25732
  fi
fi
