#!/bin/bash
set -euo pipefail

# Vendor Composer dependencies for the Cloud Foundry Linux stack so the app
# can stage on offline environments where the buildpack cannot reach
# packagist.org. The dd-trace-php native extensions are provided by the
# Datadog Cloud Foundry buildpack itself when DD_APM_INSTRUMENTATION_ENABLED
# is set.

rm -rf vendor
composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader
