################################################################################
# PowerShell Profile
# Cross-platform PowerShell configuration (Windows/Linux/macOS)
################################################################################

################################################################################
# Environment Variables
################################################################################

$env:RIPGREP_CONFIG_PATH = "$HOME\.ripgreprc"
$env:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"

################################################################################
# Modern CLI Tools Integration
################################################################################

# Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# Zoxide (replaces cd with smart jumping)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
    # cdi = interactive selection with fzf
    function cdi { zi }
}

# Atuin (shell history)
if (Get-Command atuin -ErrorAction SilentlyContinue) {
    Invoke-Expression (&atuin init powershell --disable-up-arrow)
}

# Carapace (completions)
if (Get-Command carapace -ErrorAction SilentlyContinue) {
    $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    # Enable fzf-style completion if fzf is available
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $env:CARAPACE_FZF = '1'
    }
    carapace _carapace | Out-String | Invoke-Expression
}

# FZF integration
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        $command = Get-Content (Get-PSReadLineOption).HistorySavePath | fzf --tac --no-sort
        if ($command) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
        }
    }
}

################################################################################
# Aliases - Modern replacements
################################################################################

# Eza (modern ls with icons and git)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Alias -Name ls -ErrorAction SilentlyContinue
    function ls { eza --icons --group-directories-first $args }
    function ll { eza -l --icons --git --group-directories-first $args }
    function la { eza -la --icons --git --group-directories-first $args }
    function lt { eza --tree --icons --level=2 $args }
    function tree { eza --tree --icons $args }
}

# Bat (modern cat with syntax highlighting)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Alias -Name cat -ErrorAction SilentlyContinue
    function cat { bat --paging=never $args }
    function catp { bat $args }
    $env:MANPAGER = "bat -l man -p"
}

# Fd (modern find)
if (Get-Command fd -ErrorAction SilentlyContinue) {
    function find { fd $args }
}

# Dust (modern du)
if (Get-Command dust -ErrorAction SilentlyContinue) {
    function du { dust $args }
}

# Duf (modern df)
if (Get-Command duf -ErrorAction SilentlyContinue) {
    function df { duf $args }
}

# Bottom (modern top/htop)
if (Get-Command btm -ErrorAction SilentlyContinue) {
    function top { btm $args }
    function htop { btm $args }
}

# Procs (modern ps)
if (Get-Command procs -ErrorAction SilentlyContinue) {
    # Don't override ps as it's a built-in alias
    function pss { procs $args }
}

# Ripgrep (modern grep)
if (Get-Command rg -ErrorAction SilentlyContinue) {
    function grep { rg $args }
}

# Tealdeer (simplified man pages)
if (Get-Command tldr -ErrorAction SilentlyContinue) {
    function help { tldr $args }
}

# Lazygit (terminal git UI)
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit
}

# Lazydocker (terminal docker UI)
if (Get-Command lazydocker -ErrorAction SilentlyContinue) {
    Set-Alias -Name lzd -Value lazydocker
}

# Glow (terminal markdown viewer)
if (Get-Command glow -ErrorAction SilentlyContinue) {
    function readme { glow README.md }
}

################################################################################
# Aliases - Navigation
################################################################################

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Common directories
function dls { Set-Location $HOME\Downloads }
function docs { Set-Location $HOME\Documents }
function dt { Set-Location $HOME\Desktop }

################################################################################
# Aliases - General
################################################################################

Set-Alias -Name c -Value Clear-Host
Set-Alias -Name g -Value git
Set-Alias -Name which -Value Get-Command

function reload { & $PROFILE }
function path { $env:PATH -split ';' }

################################################################################
# Aliases - Time
################################################################################

function now { Get-Date -Format "yyyy-MM-ddTHH:mm:ss" }
function unow { (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") }
function nowdate { Get-Date -Format "yyyy-MM-dd" }
function timestamp { [int][double]::Parse((Get-Date -UFormat %s)) }
function week { Get-Date -Format "yyyy-'W'ww" }

################################################################################
# Aliases - Networking
################################################################################

function publicip { (Invoke-WebRequest -Uri "https://ipinfo.io/ip" -UseBasicParsing).Content.Trim() }
function localip { (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" }).IPAddress }
function flushdns { Clear-DnsClientCache; Write-Host "DNS cache flushed" }

################################################################################
# Aliases - System
################################################################################

function lock { rundll32.exe user32.dll,LockWorkStation }
function hibernate { shutdown.exe /h }
function reboot { shutdown.exe /r /t 0 }
function poweroff { shutdown.exe /s /t 0 }

# System info
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    function sysinfo { fastfetch }
} elseif (Get-Command neofetch -ErrorAction SilentlyContinue) {
    function sysinfo { neofetch }
}

################################################################################
# Aliases - Development
################################################################################

Set-Alias -Name dk -Value docker

# Python virtual environment
function va {
    if (Test-Path ".\.venv\Scripts\Activate.ps1") {
        . .\.venv\Scripts\Activate.ps1
    } elseif (Test-Path ".\venv\Scripts\Activate.ps1") {
        . .\venv\Scripts\Activate.ps1
    } else {
        Write-Host "No virtual environment found (.venv or venv)"
    }
}

function ve { python -m venv .\.venv }

# Chezmoi shortcut
function chezmoiconf { Set-Location (chezmoi source-path) }

################################################################################
# Aliases - Weather
################################################################################

function weather {
    (Invoke-WebRequest -Uri "https://wttr.in/?format=%l:+(%C)+%c++%t+[%h,+%w]" -UseBasicParsing).Content
}

function forecast {
    (Invoke-WebRequest -Uri "https://wttr.in?F" -UseBasicParsing).Content
}

################################################################################
# PSReadLine Configuration
################################################################################

Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Colors
Set-PSReadLineOption -Colors @{
    Command   = 'Green'
    Parameter = 'Gray'
    String    = 'DarkCyan'
}

################################################################################
# Startup Message
################################################################################

Write-Host "PowerShell $($PSVersionTable.PSVersion) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
