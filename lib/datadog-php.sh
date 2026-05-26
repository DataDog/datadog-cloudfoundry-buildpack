#!/usr/bin/env bash

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

# Datadog PHP single-step APM instrumentation.
# Sourced as .profile.d/99-datadog-php.sh, after php_buildpack's own profile
# scripts. Invokes the official installer documented at
# https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/php/.

dd_php_log()    { echo "[datadog-php] $*"; }
dd_php_warn()   { echo "[datadog-php] WARN: $*"; }
dd_php_err()    { echo "[datadog-php] ERROR: $*" >&2; }
dd_php_indent() { sed 's/^/[datadog-php]   /'; }

# Skip silently when SSI is disabled (avoid noise for non-Datadog apps).
if [ -z "${DD_APM_INSTRUMENTATION_ENABLED:-}" ] || [ "${DD_APM_INSTRUMENTATION_ENABLED}" = "false" ]; then
  return 0
fi

dd_php_log "starting (DD_APM_INSTRUMENTATION_ENABLED=${DD_APM_INSTRUMENTATION_ENABLED})"

if [ -z "${DEPS_DIR:-}" ]; then
  dd_php_warn "DEPS_DIR is unset, skipping ddtrace install"
  return 0
fi

php_buildpack_dir=""
for dir in "${DEPS_DIR}"/*/; do
  if grep -q -E '^name: php$' "${dir%/}/config.yml" 2>/dev/null; then
    php_buildpack_dir="${dir%/}"
    break
  fi
done
if [ -z "$php_buildpack_dir" ]; then
  dd_php_log "no php buildpack found under ${DEPS_DIR}, skipping"
  return 0
fi
dd_php_log "detected php buildpack at ${php_buildpack_dir}"

php_bin=""
if command -v php >/dev/null 2>&1; then
  php_bin="$(command -v php)"
  dd_php_log "found php on PATH: ${php_bin}"
elif [ -x "${HOME}/php/bin/php" ]; then
  php_bin="${HOME}/php/bin/php"
  dd_php_log "found php at ${php_bin} (not on PATH)"
else
  dd_php_err "php binary not found on PATH or at \$HOME/php/bin/php"
  dd_php_err "  HOME=${HOME}"
  dd_php_err "  PATH=${PATH}"
  return 0
fi

if [ -d "${HOME}/php/lib" ]; then
  export LD_LIBRARY_PATH="${HOME}/php/lib:${LD_LIBRARY_PATH:-}"
  dd_php_log "exported LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
fi

if ! "$php_bin" -v >/dev/null 2>&1; then
  php_v_output="$("$php_bin" -v 2>&1)"
  dd_php_err "'${php_bin} -v' failed; output:"
  printf '%s\n' "$php_v_output" | dd_php_indent
  return 0
fi
dd_php_log "php -v output:"
"$php_bin" -v 2>&1 | dd_php_indent

DATADOG_DIR="${DATADOG_DIR:-/home/vcap/app/.datadog}"
DD_TRACE_PHP_VERSION="${DD_TRACE_PHP_VERSION:-1.19.2}"
INSTALLER="${DATADOG_DIR}/datadog-setup.php"
INSTALLER_URL="https://github.com/DataDog/dd-trace-php/releases/download/${DD_TRACE_PHP_VERSION}/datadog-setup.php"

dd_php_log "downloading installer ${DD_TRACE_PHP_VERSION} from ${INSTALLER_URL}"
if ! curl -fsSL --max-time 60 "$INSTALLER_URL" -o "$INSTALLER"; then
  curl_exit=$?
  dd_php_err "curl failed with exit ${curl_exit} for ${INSTALLER_URL}"
  return 0
fi
dd_php_log "downloaded $(wc -c < "$INSTALLER" 2>/dev/null) bytes to ${INSTALLER}"

installer_args="--php-bin=${php_bin}"
if [ "${DD_PROFILING_ENABLED:-}" = "true" ]; then
  installer_args="${installer_args} --enable-profiling"
  dd_php_log "DD_PROFILING_ENABLED=true, adding --enable-profiling"
fi

dd_php_log "running: ${php_bin} ${INSTALLER} ${installer_args}"
dd_php_log "----- installer output -----"
"$php_bin" "$INSTALLER" $installer_args 2>&1 | dd_php_indent
installer_exit=${PIPESTATUS[0]}
dd_php_log "----- end installer output (exit ${installer_exit}) -----"
if [ "$installer_exit" -ne 0 ]; then
  dd_php_err "installer failed with exit ${installer_exit}"
  return 0
fi

dd_php_log "verifying ddtrace is loaded by ${php_bin}"
if "$php_bin" -m 2>/dev/null | grep -qi '^ddtrace$'; then
  dd_php_log "ddtrace extension successfully loaded"
else
  dd_php_warn "ddtrace extension is NOT loaded; 'php -m' output:"
  "$php_bin" -m 2>&1 | dd_php_indent
  scan_dir=$("$php_bin" -i 2>/dev/null | sed -n 's/^Scan this dir for additional .ini files => //p' | head -1 | tr -d '[:space:]')
  if [ -n "$scan_dir" ] && [ -d "$scan_dir" ]; then
    dd_php_warn "scan dir contents (${scan_dir}):"
    ls -la "$scan_dir" 2>&1 | dd_php_indent
  fi
  extension_dir=$("$php_bin" -i 2>/dev/null | sed -n 's/^extension_dir => \([^ ]*\).*/\1/p' | head -1)
  if [ -n "$extension_dir" ] && [ -d "$extension_dir" ]; then
    dd_php_warn "extension_dir contents (${extension_dir}):"
    ls -la "$extension_dir" 2>&1 | dd_php_indent
  fi
fi

dd_php_log "done"
