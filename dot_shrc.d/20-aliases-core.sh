# -*-mode:bash-*- vim:ft=bash

################################################################################
# ~/.shrc.d/20-aliases-core.sh
# Core: better defaults, navigation, files, time.
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
# Redefine standard commands to improve their behavior
################################################################################

# Starts calculator with math support.
alias bc='bc -l'

# Makes file commands verbose.
alias cp='cp -v';
alias mv='mv -v';

# Displays drives and space in human readable format.
alias df='df -h'

# Colorizes diff output, if possible.
if type 'colordiff' &> /dev/null; then
    alias diff='colordiff'
fi

# Prints disk usage per directory non-recursively, in human readable format.
alias du='du -h -d1'

# Colorizes the `grep` output.
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Colorizes listings.
if ls --color &> /dev/null; then
    # GNU `ls`
    colorflag='--color=auto'
    export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
else
    # macOS `ls`
    colorflag='-G'
    export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
fi
if type 'dir' &> /dev/null; then
    alias dir='dir --color=auto'
fi
if type 'vdir' &> /dev/null; then
    alias vdir='vdir --color=auto'
fi

# Uses human sizes, classifications, and color output for `ls`.
alias ls='command ls -Fh ${colorflag}'

# Creates parent directories on demand.
alias mkdir='mkdir -pv'

# Makes `mount` command output pretty and with a human readable format.
alias mount='mount | column -t'

# Disables wrapping of long lines in Nano.
alias nano='nano -w';

# Stops ping after sending 4 ECHO_REQUEST packets.
alias ping='ping -c 4'

# Improves top with modern alternatives.
if type 'atop' &> /dev/null; then
    alias top='atop'
elif type 'htop' &> /dev/null; then
    alias top='htop'
elif type 'ntop' &> /dev/null; then
    if [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
        alias top='ntop'
    fi
fi

# Enables simple aliases to be sudo'ed.
# See http://www.gnu.org/software/bash/manual/bashref.html#Aliases
alias sudo='sudo ';

################################################################################
# Easier navigation
################################################################################

# Nagivates to the last used directory.
alias cd-='cd -'

# Nagivates up a directory.
alias cd..='cd ..'
alias ..='cd ..'

# Nagivates up two directories.
alias ...='cd ../../../'

# Nagivates up three directories.
alias ....='cd ../../../../'

# Nagivates up four directories.
alias .....='cd ../../../../'
alias .4='cd ../../../../'

# Nagivates up five directories.
alias .5='cd ../../../../..'

################################################################################
# Directory browsing
################################################################################

# Lists visible files in long format.
alias l='ls -l'

# Lists all files in long format, excluding `.` and `..`.
alias ll='ls -lA'

# Lists directories only, in long format.
alias lsd='ls -l | grep --color=never "^d"'

# Lists hidden files in long format.
alias lsh='ls -dlA .?*'

################################################################################
# File management
################################################################################

# Copies a file securely.
alias cpv='rsync -ah --info=progress2'

# Finds directories.
alias fd='find . -type d -name'

# Finds files.
alias ff='find . -type f -name'

################################################################################
# General aliases
################################################################################

# Clears the console screen.
alias c='clear'

# Searches history.
alias h='history_search' # see file `functions`
alias hs='history_session_search' # see file `functions`

# Sets editors and defaults.
alias edit='vim'
alias svi='sudo vi'
alias vi=vim
alias vis='vim "+set si"'

# Reloas the shell.
alias reload='exec $SHELL -l'

# Reloads the configuration.
if [ -n "$ZSH_VERSION" ]; then
    alias resource='. $HOME/.zshrc'
else
    alias resource='. $HOME/.bash_profile'
fi

################################################################################
# Time
################################################################################

# Gets local/UTC date and time in ISO-8601 format `YYYY-MM-DDThh:mm:ss`.
alias now='date +"%Y-%m-%dT%H:%M:%S"'
alias unow='date -u +"%Y-%m-%dT%H:%M:%S"'

# Gets date in `YYYY-MM-DD` format`
alias nowdate='date +"%Y-%m-%d"'
alias unowdate='date -u +"%Y-%m-%d"'

# Gets time in `hh:mm:ss` format`
alias nowtime='date +"%T"'
alias unowtime='date -u +"%T"'

# Gets Unix time stamp`
alias timestamp='date -u +%s'

# Gets week number in ISO-8601 format `YYYY-Www`.
alias week='date +"%Y-W%V"'

# Gets weekday number.
alias weekday='date +"%u"'
