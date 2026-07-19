#!/bin/sh

set -eu

if [ "$#" -gt 0 ]; then
  printf 'Usage: ./install.sh\n' >&2
  exit 2
fi

source_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
target=${XDG_CONFIG_HOME:-"$HOME/.config"}/nvim

if [ "$target" = "$source_dir" ]; then
  printf 'Refusing to install over the source checkout: %s\n' "$target" >&2
  exit 1
fi

data_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/nvim
state_dir=${XDG_STATE_HOME:-"$HOME/.local/state"}/nvim
cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/nvim

printf 'Removing existing Neovim config and runtime data:\n'
printf '  %s\n' "$target" "$data_dir" "$state_dir" "$cache_dir"
rm -rf "$target" "$data_dir" "$state_dir" "$cache_dir"

mkdir -p "$target"
cp "$source_dir/init.lua" "$source_dir/lazy-lock.json" "$source_dir/stylua.toml" "$target/"
cp -R "$source_dir/lua" "$target/lua"

printf 'Installed AsheNVim to %s\n' "$target"
