# -*-mode:bash-*- vim:ft=bash

################################################################################
# ~/.shrc.d/23-aliases-paths.sh
# Paths, config shortcuts, misc.
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
# Common paths
################################################################################

# Navigates to user paths.
alias dls='cd $HOME/Downloads'
alias docs='cd $HOME/Documents'
alias dt='cd $HOME/Desktop'

################################################################################
# Configuration paths
################################################################################

# Navigates to Chezmoi's local repo.
if command -v chezmoi > /dev/null; then
    if [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
        # shellcheck disable=SC2046,SC2139
        # TODO verify
        alias chezmoiconf="cd $(chezmoi source-path | tr '\\/' '/' | tr -d ':' | awk '{print "/"$1}')"
    else
        alias chezmoiconf='cd $(chezmoi source-path)'
    fi
else
    alias chezmoiconf='cd $HOME/.local/share/chezmoi'
fi

# Navigates to Powershell's profile location.
if [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias powershellconf='cd $HOME/Documents/PowerShell'
else
    alias powershellconf='cd $HOME/.config/powershell'
fi

################################################################################
# Varia
################################################################################

# Pastes the contents of the clipboard.
if command -v pbpaste > /dev/null; then
    alias cbpaste='pbpaste'
elif command -v xclip > /dev/null; then
    alias cbpaste='xclip -i -selection clipboard -o'
elif command -v xsel > /dev/null; then
    alias cbpaste='xsel -bo'
elif command -v clipboard > /dev/null; then
    alias cbpaste='clipboard'
elif command -v powershell > /dev/null; then
    alias cbpaste='powershell -NoProfile -Command "Get-Clipboard"'
fi

# Calculates MD5 hashes.
if ! command -v md5sum > /dev/null; then
    if command -v md5 > /dev/null; then
        alias md5sum='md5 -r'
    else
        alias md5sum='openssl md5 -r'
    fi
fi

# Calculates SHA1 hashes.
if ! command -v sha1sum > /dev/null; then
    if command -v shasum > /dev/null; then
        alias sha1sum='shasum -a 1 -p'
    else
        alias sha1sum='openssl sha1 -r'
    fi
fi

# Calculates SHA256 hashes.
if ! command -v sha256sum > /dev/null; then
    if command -v shasum > /dev/null; then
        alias sha256sum='shasum -a 256 -p'
    else
        alias sha256sum='openssl sha256 -r'
    fi
fi

# Displays detailed weather and forecast.
if command -v curl > /dev/null; then
    alias forecast='curl --silent --compressed --max-time 10 --url "https://wttr.in?F"'
else
    alias forecast='wget -qO- --compression=auto --timeout=10 "https://wttr.in?F"'
fi

# Displays current weather.
if command -v curl > /dev/null; then
    alias weather='curl --silent --compressed --max-time 10 --url "https://wttr.in/?format=%l:+(%C)+%c++%t+\[%h,+%w\]"'
else
    alias weather='wget -qO- --compression=auto --timeout=10 "https://wttr.in/?format=%l:+(%C)+%c++%t+\[%h,+%w\]"'
fi
