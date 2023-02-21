#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.
HOME_DIR="${HOME_DIR:-/home/vcap/}"
DD_DETECTED_BUILDPACK=""
if [ -f "${HOME_DIR}"/staging_info.yml ]; then
    DD_DETECTED_BUILDPACK=$(cat "${HOME_DIR}"/staging_info.yml | jq '.detected_buildpack')
elif [ -f "${BUILD_DIR}"/package.json ]; then
    DD_DETECTED_BUILDPACK="node"
fi
if echo "${DD_DETECTED_BUILDPACK}" | grep -q "node" ; then
    DD_TAGS_SEPARATOR=", "
else
    DD_TAGS_SEPARATOR=" "
fi
export DD_TAGS_SEPARATOR