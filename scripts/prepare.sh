#!/usr/bin/env bash

set -euxo pipefail

SRCDIR=$(pwd)

DOWNLOAD_BASE_URL="https://s3.amazonaws.com/apt.datadoghq.com/pool/d/da/datadog-"
TRACEAGENT_DOWNLOAD_URL=${DOWNLOAD_BASE_URL}"agent_"
IOT_AGENT_DOWNLOAD_URL=${DOWNLOAD_BASE_URL}"iot-agent_"
DOGSTATSD_DOWNLOAD_URL=${DOWNLOAD_BASE_URL}"dogstatsd_"
DOWNLOAD_URL_TAIL="-1_amd64.deb"

AGENT_DEFAULT_VERSION="7.41.1"
VERSION=${VERSION:-${AGENT_DEFAULT_VERSION}}

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

  curl -L ${iot_agent_download_url} -o $TMPDIR/datadog-agent.deb
  pushd ${TMPDIR}
    dpkg -x datadog-agent.deb .
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
  curl -LS "https://buildpacks.cloudfoundry.org/dependencies/ruby/ruby_3.0.5_linux_x64_cflinuxfs4_098393c3.tgz" -o  ${SRCDIR}/lib/ruby_3.0.5.tgz
}

function cleanup() {
  rm -rf ${TMPDIR}
}

function main() {
  trap cleanup EXIT 

  if [ ! -f ${SRCDIR}/lib/dogstatsd ] || [ ! -f ${SRCDIR}/lib/trace-agent ]; then
    DOWNLOAD="true"
  elif [ ! -f ${SRCDIR}/lib/agent ]; then
    DOWNLOAD="true"
  elif [ -n "${REFRESH_ASSETS}" ]; then
    DOWNLOAD="true"
  fi

  if [ -n "${DOWNLOAD}" ]; then
    # Delete the old ones
    rm -f ${SRCDIR}/lib/agent
    rm -f ${SRCDIR}/lib/dogstatsd
    rm -f ${SRCDIR}/lib/trace-agent
    rm -f ${SRCDIR}/lib/ruby_3.0.5.tgz

    # Download the new ones
    download_trace_agent ${VERSION}
    chmod +x ${SRCDIR}/lib/trace-agent

    download_iot_agent ${VERSION}
    chmod +x ${SRCDIR}/lib/agent

    download_dogstatsd ${VERSION}
    chmod +x ${SRCDIR}/lib/dogstatsd

    download_ruby
  fi
}


main
