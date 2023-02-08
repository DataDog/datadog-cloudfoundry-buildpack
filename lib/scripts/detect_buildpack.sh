#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.
BUILD_DIR="${BUILD_DIR:-/tmp/app}"
DD_DETECTED_BUILDPACK=""
if [ -f "${BUILD_DIR}"/staging_info.yml ]; then
    DD_DETECTED_BUILDPACK=$(cat "${BUILD_DIR}"/staging_info.yml | jq '.detected_buildpack')
elif [ -f "${BUILD_DIR}"/package-lock.json ] || [ -f "${BUILD_DIR}"/yarn.lock ]; then
    DD_DETECTED_BUILDPACK="node"
fi
if echo "${DD_DETECTED_BUILDPACK}" | grep -q "node" ; then
    LEGACY_TAGS_FORMAT=true
else
    LEGACY_TAGS_FORMAT=false
fi
export LEGACY_TAGS_FORMAT
export DD_DETECTED_BUILDPACK