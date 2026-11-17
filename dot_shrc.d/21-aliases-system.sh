# -*-mode:bash-*- vim:ft=bash

################################################################################
# ~/.shrc.d/21-aliases-system.sh
# System: network, power, sysadmin, macOS.
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
# Networking
################################################################################

# NII GPU servers: connect directly or append a remote command.
alias gpu7='ssh gpu7'
alias g7='ssh gpu7'
alias gpu8='ssh gpu8'
alias g8='ssh gpu8'

# Pings hostname(s) 30 times in quick succession.
if [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias fastping='ping -n 30'
else
    alias fastping='ping -c 30 -i.2'
fi

# Flushes the DNS cache.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias flushdns='dscacheutil -flushcache; sudo killall -HUP mDNSResponder;echo DNS cache flushed'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias flushdns='ipconfig //flushdns'
else
    alias flushdns='sudo /etc/init.d/dns-clean restart && echo DNS cache flushed'
fi

# Gets all IP addresses.
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Gets local IP address.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias localip='ipconfig getifaddr en0'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    # shellcheck disable=SC2142
    alias localip="netstat -rn | grep -w '0.0.0.0' | awk '{ print \$4 }'"
else
    alias localip="ip route get 1 | awk '{print \$NF;exit}'"
fi

# Gets external IP address.
if command -v dig &> /dev/null; then
    alias publicip='dig +short myip.opendns.com @resolver1.opendns.com'
elif command -v curl > /dev/null; then
    alias publicip='curl --silent --compressed --max-time 5 --url "https://ipinfo.io/ip"'
else
    alias publicip='wget -qO- --compression=auto --timeout=5 "https://ipinfo.io/ip"'
fi

# Sends HTTP requests.
command -v lwp-request &> /dev/null && for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    #shellcheck disable=SC2139
    alias $method="lwp-request -m '$method'"
done
unset method;

################################################################################
# Power management
################################################################################

# Locks the session.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias lock='pmset displaysleepnow'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias lock='rundll32.exe user32.dll,LockWorkStation'
elif command -v vlock &> /dev/null; then
    alias lock='vlock --all'
elif command -v gnome-screensaver-command &> /dev/null; then
    alias lock='gnome-screensaver-command --lock'
fi

# Hibernates the system.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias hibernate='pmset sleep now'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias hibernate='shutdown.exe /h'
else
    alias hibernate='systemctl suspend'
fi

# Restarts the system.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias reboot='osascript -e "tell application \"System Events\" to restart"'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias reboot='shutdown.exe /r'
else
    alias reboot='sudo /sbin/reboot'
fi

# Shuts down the system.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias poweroff='osascript -e "tell application \"System Events\" to shut down"'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias poweroff='shutdown.exe /s'
else
    alias poweroff='sudo /sbin/poweroff'
fi

################################################################################
# Sysadmin
################################################################################

# Lists drive mounts.
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias mnt='mount | grep -E ^/dev | column -t'
elif [[ "$OSTYPE" =~ ^(cygwin|mingw|msys) ]]; then
    alias mnt='mount | sed "s/Program Files/Program-Files/i" | column -t'
else
    # shellcheck disable=SC2142
    alias mnt="mount | awk -F' ' '{ printf \"%s\t%s\n\",\$1,\$3; }' | column -t | egrep ^/dev/ | sort"
fi

# Prints each $PATH entry on a separate line.
alias path='echo -e ${PATH//:/\\n}'

# Displays information about the system.
for command in winfetch neofetch screenfetch; do
    if type $command &> /dev/null; then
        alias sysinfo='$command'
        break
    fi
done

################################################################################
# macOS
################################################################################

if [[ "$OSTYPE" =~ ^darwin ]]; then
    # Toggles display of desktop icons.
    alias hidedesktop='defaults write com.apple.finder CreateDesktop -bool false && killall Finder'
    alias showdesktop='defaults write com.apple.finder CreateDesktop -bool true && killall Finder'

    # Toggles hidden files in Finder.
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'

    # Toggles Spotlight.
    alias spotoff='sudo mdutil -a -i off'
    alias spoton='sudo mdutil -a -i on'
fi
