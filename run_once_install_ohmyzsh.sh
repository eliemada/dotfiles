#!/bin/bash
################################################################################
# run_once_install_ohmyzsh.sh
# Install Oh My Zsh and required plugins (run once by chezmoi)
################################################################################

set -euo pipefail

REPO_ROOT="https://github.com"
OH_MY_ZSH_INSTALL_SCRIPT="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found in PATH." >&2
    exit 1
  fi
}

install_oh_my_zsh() {
  if [ -d "$ZSH_DIR" ]; then
    return
  fi

  ensure_command curl
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OH_MY_ZSH_INSTALL_SCRIPT")"
}

install_plugin() {
  local name="$1"
  local url="$2"
  local plugin_dir="$ZSH_CUSTOM_DIR/plugins/$name"

  ensure_command git
  mkdir -p "$(dirname "$plugin_dir")"

  if [ -d "$plugin_dir/.git" ]; then
    git -C "$plugin_dir" pull --ff-only
  else
    git clone "$url" "$plugin_dir"
  fi
}

install_oh_my_zsh
install_plugin "zsh-autosuggestions" "$REPO_ROOT/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "$REPO_ROOT/zsh-users/zsh-syntax-highlighting"
