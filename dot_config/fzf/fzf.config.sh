#!/bin/bash
################################################################################
# ~/.config/fzf/fzf.config.sh
# FZF configuration with previews and catppuccin theme
################################################################################

# Use fd instead of find (faster, respects .gitignore)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
fi

# Catppuccin Mocha theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--height=80% \
--layout=reverse \
--border=rounded \
--margin=1 \
--padding=1 \
--info=inline \
--separator='─' \
--scrollbar='│' \
--preview-window='right:50%:border-left' \
--bind='ctrl-/:toggle-preview' \
--bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' \
--bind='ctrl-d:half-page-down' \
--bind='ctrl-u:half-page-up'"

# File preview with bat
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
fi

# Directory preview with eza
if command -v eza &> /dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons --level=2 {}'"
fi

# History search options
export FZF_CTRL_R_OPTS="
--preview 'echo {}' --preview-window up:3:hidden:wrap
--bind 'ctrl-/:toggle-preview'
--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
--color header:italic
--header 'Press CTRL-Y to copy command'"

################################################################################
# FZF Functions
################################################################################

# Interactive cd with preview
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'eza --tree --color=always --icons --level=2 {}') && cd "$dir"
}

# Interactive file open
fopen() {
    local file
    file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}') && ${EDITOR:-vim} "$file"
}

# Git commit browser
fglog() {
    git log --oneline --color=always | fzf --ansi --preview 'git show --color=always {1}' --bind 'enter:execute(git show {1})'
}

# Git branch switcher
fgbranch() {
    local branch
    branch=$(git branch -a --color=always | grep -v HEAD | fzf --ansi --preview 'git log --oneline --color=always {1}' | sed 's/^[* ]*//' | sed 's/remotes\/origin\///')
    [ -n "$branch" ] && git checkout "$branch"
}

# Kill process interactively
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header='[kill process]' | awk '{print $2}')
    [ -n "$pid" ] && echo "$pid" | xargs kill -${1:-9}
}

# SSH host selector
fssh() {
    local host
    host=$(grep "^Host " ~/.ssh/config 2>/dev/null | grep -v '*' | awk '{print $2}' | fzf --header='[ssh host]')
    [ -n "$host" ] && ssh "$host"
}
