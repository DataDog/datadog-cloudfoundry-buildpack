#!/usr/bin/env bash

set -euxo pipefail

main() {
  VERSION=${VERSION:-$(cat VERSION)}
  srcDir=$(pwd)
  name="datadog-cloudfoundry-buildpack"
  zip="${name}-${VERSION}.zip"

  rm -f ${zip}

  pushd ${srcDir}
    zip -r "${zip}" lib bin VERSION
  popd
}

main "$@"
