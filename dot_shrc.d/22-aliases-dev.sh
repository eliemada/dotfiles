# -*-mode:bash-*- vim:ft=bash

################################################################################
# ~/.shrc.d/22-aliases-dev.sh
# Applications and development.
# Sourced (in filename order) by ~/.bashrc and ~/.zshrc.
################################################################################
#
# OSTYPE values used:
#     - darwin: macOS
#     - cygwin: Cygwin POSIX-compatible environment for Windows
#     - mingw: MinGW Minimalist GNU for Windows
#     - msys: MinGW Lightweight shell and GNU utilities for Windows

# shellcheck shell=bash

################################################################################
# Applications
################################################################################

# Opens file/URL (in) browsers.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias browse='open'
    alias brave='open -a Brave\ Browser'
    alias firefox='open -a Firefox'
    alias wolf='open -a LibreWolf'
    alias safari='open -a Safari'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias browse='start'
    alias chrome='start chrome'
    alias edge='microsoft-edge'
    alias iexplore='start iexplore'
    alias firefox='start firefox'
    alias opera='start opera'
    #alias safari='start safari'
else
    # alias browse='x-www-browser' #xdg-open
    alias chrome='chromium'
    #alias edge='microsoft-edge'
    #alias firefox='firefox'
    #alias opera='opera'
    #alias safari='safari'
fi

# Enters the Starship cross-shell prompt.
if [ -n "$ZSH_VERSION" ]; then
    # shellcheck disable=SC2034
    if typeset -f prompt_powerlevel9k_teardown > /dev/null; then
        alias ss='prompt_powerlevel9k_teardown && eval "$(starship init zsh)"'
    else
        alias ss='eval "$(starship init zsh)"'
    fi
else
    alias ss='eval "$(starship init bash)"'
fi

################################################################################
# Development
################################################################################

# Creates shortcuts for Docker.
alias dk='docker'
alias dco='docker-compose'

# Creates shortcut for Git.
alias g='git'

# Activates Python virtual environment `venv`.
alias va='if [ -d ./.venv ]; then \. ./.venv/bin/activate; elif [ -d ./venv ]; then \. ./venv/bin/activate; fi'

# Creates Python virtual environment `venv`.
alias ve='python3 -m venv ./.venv'
