#!/bin/bash
################################################################################
# ~/.shrc.d/50-env-tools.sh
# Common shell configuration shared between bash and zsh
################################################################################

################################################################################
# Environment variables
################################################################################
export PYTHONSTARTUP="$HOME/.pythonrc"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export EZA_CONFIG_DIR="$HOME/.config/eza"

# Claude Code: disable the built-in self-updater. The `claude` binary is managed
# by chezmoi (.chezmoiexternal.toml.tmpl pulls it from GitHub releases `latest`),
# so chezmoi is the source of truth — let it handle updates, not the background
# updater. Force a refresh anytime with: chezmoi apply --refresh-externals
export DISABLE_AUTOUPDATER=1

################################################################################
# Modern CLI tools integration
################################################################################

# Zoxide alias (init is done at end of .bashrc/.zshrc to properly override cd)
if command -v zoxide > /dev/null 2>&1; then
  alias cdi='zi'  # interactive selection with fzf
fi

# Atuin (shell history)
if command -v atuin > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(atuin init zsh --disable-up-arrow)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(atuin init bash --disable-up-arrow)"
  fi
fi

# Eza (modern ls with icons and git)
if command -v eza > /dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --group-directories-first'
  alias la='eza -la --icons --git --group-directories-first'
  alias lt='eza --tree --icons --level=2'
  alias lta='eza --tree --icons --level=2 -a'
  alias tree='eza --tree --icons'
fi

# Bat (modern cat)
if command -v bat > /dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias catp='bat'  # with pager
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi

# Fd (modern find)
if command -v fd > /dev/null 2>&1; then
  alias find='fd'
fi

# FZF configuration
if [ -f "$HOME/.config/fzf/fzf.config.sh" ]; then
  source "$HOME/.config/fzf/fzf.config.sh"
fi

# Carapace (multi-shell completions)
if command -v carapace > /dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  if [ -n "$ZSH_VERSION" ]; then
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
    source <(carapace _carapace zsh)
  elif [ -n "$BASH_VERSION" ]; then
    source <(carapace _carapace bash)
  fi
fi

# Tealdeer/tldr (simplified man pages)
if command -v tldr > /dev/null 2>&1; then
  alias help='tldr'
fi

# Duf (modern df)
if command -v duf > /dev/null 2>&1; then
  alias df='duf'
fi

# Bottom (modern top/htop)
if command -v btm > /dev/null 2>&1; then
  alias top='btm'
  alias htop='btm'
fi

# Procs (modern ps)
if command -v procs > /dev/null 2>&1; then
  alias ps='procs'
fi

################################################################################
# Starship prompt initialization
################################################################################
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
