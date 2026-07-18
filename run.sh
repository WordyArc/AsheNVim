#!/bin/sh

set -eu

config_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
config_home=$(dirname "$config_dir")
app_name=$(basename "$config_dir")
runtime_root=${ASHENVIM_RUNTIME_ROOT:-${TMPDIR:-/tmp}/ashenvim}

exec env \
  XDG_CONFIG_HOME="$config_home" \
  XDG_DATA_HOME="$runtime_root/data" \
  XDG_STATE_HOME="$runtime_root/state" \
  XDG_CACHE_HOME="$runtime_root/cache" \
  NVIM_APPNAME="$app_name" \
  nvim "$@"
