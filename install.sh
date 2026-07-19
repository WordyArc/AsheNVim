#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./install.sh [TARGET]

Remove the existing Neovim config and runtime data, then install a fresh copy
of AsheNVim.

TARGET defaults to $XDG_CONFIG_HOME/nvim or ~/.config/nvim.

Examples:
  ./install.sh
  ./install.sh ~/.config/AsheNVim
  NVIM_APPNAME=AsheNVim nvim
EOF
}

case ${1:-} in
  -h | --help)
    usage
    exit 0
    ;;
esac

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

source_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
target=${1:-"$config_home/nvim"}
target_parent=$(dirname "$target")

mkdir -p "$target_parent"
target_parent=$(CDPATH= cd "$target_parent" && pwd -P)
target="$target_parent/$(basename "$target")"
app_name=$(basename "$target")

if [ "$app_name" = "." ] || [ "$app_name" = ".." ]; then
  printf 'Refusing unsafe app name: %s\n' "$app_name" >&2
  exit 1
fi

if [ "$target" = "$source_dir" ] || [ "$target" = "/" ] || [ "$target" = "$HOME" ]; then
  printf 'Refusing unsafe install target: %s\n' "$target" >&2
  exit 1
fi

data_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/$app_name
state_dir=${XDG_STATE_HOME:-"$HOME/.local/state"}/$app_name
cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/$app_name

printf 'Removing existing AsheNVim installation:\n'
printf '  %s\n' "$target" "$data_dir" "$state_dir" "$cache_dir"
rm -rf "$target" "$data_dir" "$state_dir" "$cache_dir"

mkdir -p "$target"
cp "$source_dir/init.lua" "$source_dir/lazy-lock.json" "$source_dir/stylua.toml" "$target/"
cp -R "$source_dir/lua" "$target/lua"

printf 'Installed AsheNVim to %s\n' "$target"
