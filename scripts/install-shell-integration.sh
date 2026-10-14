#!/usr/bin/env bash
# Installs Farol prompt positioning hooks into a staged Ghostty resource tree.
set -euo pipefail

ghostty="${1:?Ghostty resource directory required}"
root="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="$root/Sources/Farol/ShellIntegration"
target_dir="$ghostty/shell-integration/farol"

mkdir -p "$target_dir"
cp "$source_dir"/* "$target_dir/"

append_once() {
  local path="$1"
  local marker="$2"
  local content="$3"

  if ! grep -Fq "$marker" "$path"; then
    printf '\n%s\n' "$content" >> "$path"
  fi
}

append_once \
  "$ghostty/shell-integration/zsh/.zshenv" \
  'shell-integration/farol/farol.zsh' \
  '[[ -r "${GHOSTTY_RESOURCES_DIR:-}/shell-integration/farol/farol.zsh" ]] && source "${GHOSTTY_RESOURCES_DIR}/shell-integration/farol/farol.zsh"'
append_once \
  "$ghostty/shell-integration/bash/ghostty.bash" \
  'shell-integration/farol/farol.bash' \
  '[[ -r "${GHOSTTY_RESOURCES_DIR:-}/shell-integration/farol/farol.bash" ]] && source "${GHOSTTY_RESOURCES_DIR}/shell-integration/farol/farol.bash"'
append_once \
  "$ghostty/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish" \
  'shell-integration/farol/farol.fish' \
  'if set -q GHOSTTY_RESOURCES_DIR; and test -r "$GHOSTTY_RESOURCES_DIR/shell-integration/farol/farol.fish"
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/farol/farol.fish"
end'
