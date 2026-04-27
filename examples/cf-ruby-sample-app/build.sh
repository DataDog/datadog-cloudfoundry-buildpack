#!/bin/bash
set -euo pipefail

# Cache gems for every platform listed in Gemfile.lock so vendor/cache/ also
# contains the x86_64-linux gems needed by offline Cloud Foundry staging,
# even when the script runs on a darwin dev machine.
bundle config set --local cache_all_platforms true
bundle package --all
