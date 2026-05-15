#!/usr/bin/env bash

set -euxo pipefail

SRCDIR=$(pwd)

DOWNLOAD_BASE_URL="https://s3.amazonaws.com/apt.datadoghq.com/pool/d/da/datadog-"
TRACEAGENT_DOWNLOAD_URL=${DOWNLOAD_BASE_URL}"agent_"
IOT_AGENT_DOWNLOAD_URL=${DOWNLOAD_BASE_URL}"iot-agent_"
DOGSTATSD_DOWNLOAD_URL=${DOWNLOAD_BASE_URL}"dogstatsd_"
DOWNLOAD_URL_TAIL="-1_amd64.deb"

AGENT_DEFAULT_VERSION="7.76.3"
VERSION=${VERSION:-${AGENT_DEFAULT_VERSION}}

DD_LIBRARY_PHP_VERSION="${DD_LIBRARY_PHP_VERSION:-1.19.2}"
# NTS, non-debug, x86_64-linux-gnu ABIs covering PHP 8.0–8.5 in dd-library-php 1.19.2.
DD_LIBRARY_PHP_ABIS="${DD_LIBRARY_PHP_ABIS:-20200930 20210902 20220829 20230831 20240924 20250925}"
DD_LIBRARY_PHP_BASE_URL="https://github.com/DataDog/dd-trace-php/releases/download"
DD_LIBRARY_PHP_CHECKSUMS="${SRCDIR}/scripts/dd-library-php-checksums.txt"

TMPDIR=$(mktemp -d)


function download_trace_agent() {
  local trace_version="${1:-${AGENT_DEFAULT_VERSION}}"
  local trace_agent_download_url="${TRACEAGENT_DOWNLOAD_URL}${trace_version}${DOWNLOAD_URL_TAIL}"

  curl -L ${trace_agent_download_url} -o $TMPDIR/datadog-agent.deb
  pushd ${TMPDIR}
    dpkg -x datadog-agent.deb .
  popd
  cp ${TMPDIR}/opt/datadog-agent/embedded/bin/trace-agent ${SRCDIR}/lib/trace-agent
}

function download_iot_agent() {
  local iot_version="${1:-${AGENT_DEFAULT_VERSION}}"
  local iot_agent_download_url="${IOT_AGENT_DOWNLOAD_URL}${iot_version}${DOWNLOAD_URL_TAIL}"

  curl -L ${iot_agent_download_url} -o $TMPDIR/datadog-iot-agent.deb
  pushd ${TMPDIR}
    dpkg -x datadog-iot-agent.deb .
  popd
  cp ${TMPDIR}/opt/datadog-agent/bin/agent/agent ${SRCDIR}/lib/agent
}

function download_dogstatsd() {
  local dogstatsd_version="${1:-${AGENT_DEFAULT_VERSION}}"
  local dogstatsd_download_url="${DOGSTATSD_DOWNLOAD_URL}${dogstatsd_version}${DOWNLOAD_URL_TAIL}"

  mkdir -p ${TMPDIR}
  curl -L ${dogstatsd_download_url} -o $TMPDIR/dogstatsd.deb
  pushd ${TMPDIR}
    dpkg -x dogstatsd.deb .
  popd
  cp ${TMPDIR}/opt/datadog-dogstatsd/bin/dogstatsd ${SRCDIR}/lib/dogstatsd
}

function download_ruby() {
  curl -LS "https://buildpacks.cloudfoundry.org/dependencies/ruby/ruby_3.0.5_linux_x64_cflinuxfs3_098393c3.tgz" -o  ${SRCDIR}/lib/ruby_3.0.5.tgz
}

function download_dd_library_php() {
  local version="${DD_LIBRARY_PHP_VERSION}"
  local dest="${SRCDIR}/lib/dd-library-php"

  rm -rf "${dest}"
  mkdir -p "${dest}"

  for abi in ${DD_LIBRARY_PHP_ABIS}; do
    local tarball_name="dd-library-php-${version}-x86_64-linux-gnu-${abi}.tar.gz"
    local url="${DD_LIBRARY_PHP_BASE_URL}/${version}/${tarball_name}"
    local local_path="${TMPDIR}/${tarball_name}"

    curl -fL "${url}" -o "${local_path}"

    # Look up the pinned SHA-256 for this version/ABI; fail loudly if absent.
    local expected
    expected=$(grep -E "^${version}/${abi}[[:space:]]" "${DD_LIBRARY_PHP_CHECKSUMS}" | awk '{print $2}' || true)
    if [ -z "${expected}" ]; then
      echo "ERROR: no SHA-256 entry for ${version}/${abi} in ${DD_LIBRARY_PHP_CHECKSUMS}" >&2
      exit 1
    fi
    local actual
    actual=$(shasum -a 256 "${local_path}" | awk '{print $1}')
    if [ "${expected}" != "${actual}" ]; then
      echo "ERROR: checksum mismatch for ${tarball_name}: expected ${expected}, got ${actual}" >&2
      exit 1
    fi

    # Strip leading ./ component so contents land under ${SRCDIR}/lib/dd-library-php/.
    tar -xzf "${local_path}" -C "${SRCDIR}/lib"
  done

  # AppSec ships in the same tarball but is unused by the buildpack today.
  # Dropping it cuts ~234 MB across 6 ABIs from the resulting buildpack ZIP.
  rm -rf "${dest}/appsec"
}

function cleanup() {
  rm -rf ${TMPDIR}
}

function main() {
  trap cleanup EXIT

  DOWNLOAD=${REFRESH_ASSETS:-"false"}

  if [ ! -f ${SRCDIR}/lib/dogstatsd ] || [ ! -f ${SRCDIR}/lib/trace-agent ]; then
    DOWNLOAD="true"
  elif [ ! -f ${SRCDIR}/lib/agent ]; then
    DOWNLOAD="true"
  elif [ ! -d ${SRCDIR}/lib/dd-library-php ]; then
    DOWNLOAD="true"
  fi

  if [ -n "${DOWNLOAD}" ]; then
    # Delete the old ones
    rm -f ${SRCDIR}/lib/agent
    rm -f ${SRCDIR}/lib/dogstatsd
    rm -f ${SRCDIR}/lib/trace-agent
    rm -f ${SRCDIR}/lib/ruby_3.0.5.tgz
    rm -rf ${SRCDIR}/lib/dd-library-php

    # Download the new ones
    download_trace_agent ${VERSION}
    chmod +x ${SRCDIR}/lib/trace-agent

    download_iot_agent ${VERSION}
    chmod +x ${SRCDIR}/lib/agent

    download_dogstatsd ${VERSION}
    chmod +x ${SRCDIR}/lib/dogstatsd

    download_ruby

    download_dd_library_php
  fi
}


main
