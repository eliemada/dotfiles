# Dotfiles (chezmoi)

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io). Supports **macOS**, **Linux**, and **Windows**.

## Quick Start

### macOS

```bash
# Install Homebrew if needed, then:
brew install chezmoi
chezmoi init --apply <github-username>
```

### Linux

```bash
# Option 1: Linuxbrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
chezmoi init --apply <github-username>

# Option 2: Direct install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-username>
```

### Windows (PowerShell)

```powershell
# 1. Install Scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2. Install chezmoi via Scoop
scoop install chezmoi

# 3. Initialize dotfiles
chezmoi init --apply <github-username>
```

## What Gets Installed

| Component | macOS | Linux | Windows |
|-----------|-------|-------|---------|
| Package manager | Homebrew | Linuxbrew | Scoop |
| CLI tools (starship, fzf, etc.) | ✓ | ✓ | ✓ |
| GUI apps (casks) | ✓ | ✗ | ✗ |
| JetBrains Mono Nerd Font | ✓ | ✓ | ✓ |
| GitHub identity | ✓ | ✗ | ✗ |
| KeePassXC integration | ✓ | ✗ | ✗ |

## Structure

### Shell Configuration
- `dot_zshrc` - Zsh + Oh My Zsh setup, plugins
- `dot_bashrc` - Bash startup
- `dot_bash_aliases` - Common aliases
- `dot_bash_functions` - Utility functions
- `dot_shrc.d/` - Cross-shell snippets
- `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` - PowerShell profile (Windows)

### Package Lists
- `dot_Brewfile` - macOS Homebrew (taps, formulae, casks)
- `dot_Brewfile.linux` - Linux Homebrew (CLI tools only)
- `dot_config/scoop/Scoopfile.json` - Windows Scoop packages

### Git Configuration
- `dot_gitconfig.tmpl` - Global Git config with conditional includes
- `dot_gitconfig-github` - GitHub identity (macOS only)
- `dot_gitconfig-gitlab` - GitLab/work identity (all platforms)
- `dot_gitignore_global` - Global ignore patterns

### Other Configs
- `dot_config/starship/starship.toml.tmpl` - Starship prompt
- `dot_ripgreprc` - ripgrep defaults
- `dot_nanorc.tmpl` - Nano editor config
- `dot_pythonrc` - Python REPL tweaks

### Run Scripts
- `run_onchange_brew_bundle.sh.tmpl` - Sync Homebrew packages (macOS/Linux)
- `run_onchange_scoop_install.ps1.tmpl` - Sync Scoop packages (Windows)
- `run_onchange_rtk_setup.sh.tmpl` - Configure RTK hooks for Claude Code + Codex (macOS/Linux). Re-runs on rtk version change.
- `run_onchange_rtk_setup.ps1.tmpl` - Install RTK (from GitHub release) and configure hooks (Windows). Bump `$DesiredVersion` inside the file to upgrade.
- `run_once_install_nerd_font.sh.tmpl` - Install Nerd Font (Linux)
- `run_once_configure-macos.sh` - macOS defaults (macOS only)
- `run_once_install_ohmyzsh.sh` - Install Oh My Zsh

### RTK (Rust Token Killer)

[RTK](https://www.rtk-ai.app) is a CLI proxy that strips noisy output from shell commands before it
reaches your LLM, cutting token usage by 60-90% on dev workflows. The setup is split into install
(package manager) and configure (hook patching):

- **Install** — `rtk` ships in Homebrew core (macOS + Linux); Windows pulls the official GitHub
  release zip into `%LOCALAPPDATA%\rtk\bin` and adds it to the user PATH.
- **Configure** — `run_onchange_rtk_setup.*` calls `rtk init -g --auto-patch` for Claude Code and
  `rtk init -g --codex --auto-patch` for Codex CLI. Telemetry is disabled by default.
- **Idempotent upgrades** — the macOS/Linux template embeds `rtk --version`; whenever brew upgrades
  rtk, chezmoi notices the script content changed and re-runs `init` to refresh the RTK.md and
  hook. On Windows, bump `$DesiredVersion` in the `.ps1.tmpl`.
- **Add another agent** (Cursor, Windsurf, OpenCode, etc.) — uncomment the relevant line at the
  bottom of `run_onchange_rtk_setup.sh.tmpl`.

## OS Detection

Templates use chezmoi's OS detection. You can use these flags in any `.tmpl` file:

```
{{- if .macos.enabled }}
# macOS specific
{{- else if .linux.enabled }}
# Linux specific
{{- else if .windows.enabled }}
# Windows specific
{{- end }}
```

## Common Commands

```bash
chezmoi diff              # Preview changes
chezmoi apply             # Apply changes
chezmoi apply --verbose   # Apply with details
chezmoi edit --apply FILE # Edit and apply one file
chezmoi update            # Pull latest and apply
```

## Adding New Packages

- **macOS**: Edit `dot_Brewfile`, run `chezmoi apply`
- **Linux**: Edit `dot_Brewfile.linux`, run `chezmoi apply`
- **Windows**: Edit `dot_config/scoop/Scoopfile.json`, run `chezmoi apply`

## Windows PowerShell Profile

The PowerShell profile (`Documents/PowerShell/Microsoft.PowerShell_profile.ps1`) includes:

- **Starship** prompt initialization
- **Zoxide** (`z` command for smart directory jumping)
- **Atuin** shell history
- **Carapace** completions
- **Eza** aliases (`ls`, `ll`, `la`, `lt`)
- **FZF** Ctrl+R history search
- Common aliases ported from bash (`..`, `...`, `dls`, `docs`, etc.)
- Python venv helpers (`va`, `ve`)
- Network utilities (`publicip`, `localip`, `flushdns`)
- Weather functions (`weather`, `forecast`)

## macOS-Only Features

These are excluded on Linux/Windows via `.chezmoiignore`:
- KeePassXC password manager integration
- SSH key restoration from KeePassXC
- Personal GitHub identity
- GUI applications (casks)
- Dock and macOS system configuration
