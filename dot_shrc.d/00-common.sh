#!/bin/bash
# ~/.shrc.d/00-common.sh
# Common shell configuration shared between bash and zsh

# Export common environment variables
export PYTHONSTARTUP="$HOME/.pythonrc"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Modern CLI tools integration
if command -v zoxide > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(zoxide init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(zoxide init bash)"
  fi
fi

if command -v atuin > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(atuin init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(atuin init bash)"
  fi
fi

if command -v eza > /dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -l'
  alias la='eza -la'
  alias tree='eza --tree'
fi

# Starship prompt initialization
if command -v starship > /dev/null 2>&1; then
  export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(starship init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(starship init bash)"
  fi
else
  echo "Starship not found, see https://starship.rs"
fi