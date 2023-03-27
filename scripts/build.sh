#!/usr/bin/env bash

set -euxo pipefail

SRCDIR=$(pwd)

NAME="datadog-cloudfoundry-buildpack"
VERSION=$(cat VERSION)
ZIPFILE="${NAME}-${VERSION}.zip"

main() {
  rm -f ${ZIPFILE}

  pushd ${SRCDIR}
    zip -r "${ZIPFILE}" lib bin VERSION
  popd
}

main "$@"
