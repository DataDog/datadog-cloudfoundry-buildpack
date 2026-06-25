#!/bin/bash
set -euo pipefail

# Vendor Composer dependencies into a local vendor/ folder so the app can stage
# on offline Cloud Foundry environments where the buildpack cannot reach
# packagist.org. The dependencies are pure PHP and composer.json pins the target
# platform (php 8.2 + ext-sockets), so the vendored tree is platform-independent
# and composer can run anywhere. The dd-trace-php native extensions are provided
# by the Datadog buildpack itself when DD_APM_INSTRUMENTATION_ENABLED is set.
#
# Prefer a local composer; otherwise run it in the official composer Docker image
# so no local PHP/composer toolchain is required. If neither is available, skip
# vendoring: the php_buildpack runs composer during staging, so the app can be
# pushed directly on online environments.

composer_args=(install --no-dev --no-interaction --prefer-dist --optimize-autoloader)

rm -rf vendor

if command -v composer >/dev/null 2>&1; then
    composer "${composer_args[@]}"
elif command -v docker >/dev/null 2>&1; then
    echo "composer not found; running it in the composer Docker image"
    docker run --rm \
        --volume "${PWD}":/app \
        --workdir /app \
        --user "$(id -u):$(id -g)" \
        --env COMPOSER_HOME=/tmp \
        composer:2 "${composer_args[@]}"
else
    echo "Neither composer nor Docker is available; skipping local vendoring." >&2
    echo "Pushing directly: the php_buildpack runs composer during staging (requires online staging)." >&2
fi
