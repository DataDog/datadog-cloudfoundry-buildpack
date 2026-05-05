#!/bin/bash
set -euo pipefail

# Vendor Composer dependencies and the dd-trace-php native extensions for
# the Cloud Foundry Linux stack so the app can stage on offline environments
# where the buildpack cannot reach packagist.org or github.com.
DD_TRACE_PHP_VERSION="1.19.1"
PHP_API="20220829" # PHP 8.2 ABI tag

rm -rf vendor extensions
composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

mkdir -p extensions
TARBALL="dd-library-php-${DD_TRACE_PHP_VERSION}-x86_64-linux-gnu-${PHP_API}.tar.gz"
curl -fsSL -o "$TARBALL" \
    "https://github.com/DataDog/dd-trace-php/releases/download/${DD_TRACE_PHP_VERSION}/${TARBALL}"
tar -xzf "$TARBALL" -C extensions \
    --exclude='dd-library-php/appsec'
rm -f "$TARBALL"
