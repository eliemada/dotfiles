#!/bin/sh
# EPFL VPN helpers using openconnect
# Requires: openconnect, keepassxc-cli, macOS Keychain entry "keepassxc-master"
#
# Setup (one-time):
#   security add-generic-password -a "$USER" -s "keepassxc-master" -w
#
# Usage:
#   epfl         - Connect to EPFL VPN (stays connected until you run: epfl stop)
#   epfl stop    - Disconnect from EPFL VPN
#   epfl-ssh     - Connect VPN, SSH to izar, disconnect VPN on exit

_EPFL_PID_FILE="/tmp/openconnect-epfl.pid"
_EPFL_KDBX="$HOME/Library/CloudStorage/Dropbox/PW.kdbx"
_EPFL_ENTRY="isa.epfl.ch"

# Authenticate to EPFL VPN via KeePassXC + Touch ID, return cookie in AUTHFILE
_epfl_auth() {
    local MASTER_PW EPFL_PASS EPFL_TOTP

    echo "Unlocking KeePassXC (Touch ID)..."
    MASTER_PW=$(security find-generic-password -a "$USER" -s "keepassxc-master" -w) || {
        echo "Failed. Store your master password first with:"
        echo '  security add-generic-password -a "$USER" -s "keepassxc-master" -w'
        return 1
    }

    EPFL_PASS=$(echo "$MASTER_PW" | keepassxc-cli show -q -s -a Password "$_EPFL_KDBX" "$_EPFL_ENTRY") || {
        echo "Failed to retrieve password from KeePassXC."; unset MASTER_PW; return 1
    }
    EPFL_TOTP=$(echo "$MASTER_PW" | keepassxc-cli show -q -s -t "$_EPFL_KDBX" "$_EPFL_ENTRY") || {
        echo "Failed to retrieve TOTP from KeePassXC."; unset MASTER_PW; return 1
    }
    unset MASTER_PW

    sudo -v || return 1

    echo "Authenticating to EPFL VPN..."
    AUTHFILE=$(mktemp /tmp/oc-auth.XXXXXX)

    printf '%s\n%s\n' "$EPFL_PASS" "$EPFL_TOTP" | \
        sudo openconnect vpn.epfl.ch \
            --protocol=anyconnect \
            --useragent="AnyConnect" \
            --user=enbruno \
            --passwd-on-stdin \
            --authenticate > "$AUTHFILE"

    if [ $? -ne 0 ]; then
        echo "VPN authentication failed."
        rm -f "$AUTHFILE"
        unset EPFL_PASS EPFL_TOTP
        return 1
    fi

    unset EPFL_PASS EPFL_TOTP
}

# Connect VPN in background using auth cookie
_epfl_connect() {
    eval "$(cat "$AUTHFILE")"
    rm -f "$AUTHFILE"

    echo "Connecting VPN..."
    sudo openconnect vpn.epfl.ch \
        --protocol=anyconnect \
        --useragent="AnyConnect" \
        --cookie="$COOKIE" \
        --servercert="$FINGERPRINT" \
        --background \
        --pid-file="$_EPFL_PID_FILE"

    sleep 2
    echo "VPN connected."
}

# Disconnect VPN
_epfl_disconnect() {
    if [ -f "$_EPFL_PID_FILE" ] && kill -0 "$(cat "$_EPFL_PID_FILE")" 2>/dev/null; then
        sudo kill "$(cat "$_EPFL_PID_FILE")" 2>/dev/null
        sudo rm -f "$_EPFL_PID_FILE"
        echo "VPN disconnected."
    else
        echo "VPN is not running."
        rm -f "$_EPFL_PID_FILE" 2>/dev/null
    fi
}

# Check if VPN is already connected
_epfl_is_connected() {
    [ -f "$_EPFL_PID_FILE" ] && kill -0 "$(cat "$_EPFL_PID_FILE")" 2>/dev/null
}

# epfl [stop] — connect or disconnect the EPFL VPN
epfl() {
    case "${1:-}" in
        stop|down|disconnect)
            _epfl_disconnect
            ;;
        "")
            if _epfl_is_connected; then
                echo "VPN already connected (pid $(cat "$_EPFL_PID_FILE"))."
                return 0
            fi
            _epfl_auth || return 1
            _epfl_connect
            ;;
        *)
            echo "Usage: epfl [stop]"
            ;;
    esac
}

# epfl-ssh — connect VPN, SSH to izar, disconnect VPN on exit
epfl-ssh() {
    if _epfl_is_connected; then
        echo "VPN already connected, opening SSH..."
        ssh enbruno@izar.hpc.epfl.ch "$@"
        return
    fi

    _epfl_auth || return 1
    _epfl_connect

    echo "Starting SSH..."
    ssh enbruno@izar.hpc.epfl.ch "$@"

    echo "SSH disconnected. Tearing down VPN..."
    _epfl_disconnect
}
