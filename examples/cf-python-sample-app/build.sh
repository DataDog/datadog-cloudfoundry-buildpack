#!/bin/bash
set -euo pipefail

# Download dependency wheels for the Cloud Foundry Linux stack so the app can
# stage on offline environments where pip cannot reach PyPI.
PYTHON_VERSION="3.12"
PLATFORM="manylinux2014_x86_64"

rm -rf vendor

pip download -r requirements.txt \
    -d vendor \
    --platform "$PLATFORM" \
    --python-version "$PYTHON_VERSION" \
    --implementation cp \
    --only-binary=:all:
