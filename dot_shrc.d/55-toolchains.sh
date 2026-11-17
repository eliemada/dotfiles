################################################################################
# ~/.shrc.d/55-toolchains.sh
# Language/tool installers that otherwise append themselves to ~/.zshrc.
################################################################################
# shellcheck shell=bash

# bun
if [ -d "$HOME/.bun/bin" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  [ -n "$ZSH_VERSION" ] && [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi

# Run:ai CLI (EPFL RCP cluster)
if [ -x "$HOME/.runai/bin/runai" ]; then
  export PATH="$PATH:$HOME/.runai/bin"
  if [ -n "$ZSH_VERSION" ]; then source <("$HOME/.runai/bin/runai" completion zsh)
  elif [ -n "$BASH_VERSION" ]; then source <("$HOME/.runai/bin/runai" completion bash); fi
fi
