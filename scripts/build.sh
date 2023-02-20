#!/usr/bin/env bash

set -euxo pipefail

SRCDIR=$(pwd)

NAME="datadog-cloudfoundry-buildpack"
ZIPFILE="${NAME}.zip"

main() {
      rm -f ${ZIPFILE}

  pushd ${SRCDIR}
    zip -r "${ZIPFILE}" lib bin
  popd
}

main "$@"