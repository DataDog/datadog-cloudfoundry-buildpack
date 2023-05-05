#!/usr/bin/env bash

set -euxo pipefail

main() {
  if [ -z "${VERSION}" ]; then
    echo "VERSION is required to build the buildpack"
    exit 0
  fi

  srcDir=$(pwd)
  name="datadog-cloudfoundry-buildpack"
  zip="${name}-${VERSION}.zip"

  echo "${VERSION}" > VERSION

  rm -f ${zip}

  pushd ${srcDir}
    zip -r "${zip}" lib bin VERSION
  popd
}

main "$@"
