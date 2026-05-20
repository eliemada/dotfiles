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
- `run_onchange_rtk_setup.sh.tmpl` - Configure RTK hook for Codex CLI (macOS/Linux). Claude Code's hook is now baked into chezmoi-managed `settings.json`.
- `run_onchange_rtk_setup.ps1.tmpl` - Install RTK (from GitHub release) and configure hooks (Windows). Bump `$DesiredVersion` inside the file to upgrade.
- `run_onchange_claude_mcp_setup.sh.tmpl` - Reconcile Claude MCP servers from `~/.claude/mcp-servers/*.json` via `claude mcp add-json`. Idempotent, handles orphan removal.
- `run_onchange_refresh_font_cache.sh.tmpl` - Run `fc-cache -f` after `.chezmoiexternal.toml` drops fonts (Linux).
- `run_once_configure-macos.sh` - macOS defaults (macOS only)

### Declarative externals (`.chezmoiexternal.toml.tmpl`)
- Oh My Zsh + community plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) cloned with weekly refresh
- JetBrains Mono Nerd Font (Linux only) archive download with yearly refresh

This replaced two run-scripts that were doing `git clone` and `curl | unzip` imperatively.

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

## Opt-in Features (per-machine toggles)

Some features are too machine-specific to install everywhere (e.g. EPFL VPN
helpers don't belong on Citadel workstations). They're gated by booleans in
`~/.config/chezmoi/chezmoi.toml` — `chezmoi init` prompts once and remembers.

| Toggle | What it installs | Default |
|---|---|---|
| `epfl_vpn` | `~/.shrc.d/epfl-vpn.sh` (`epfl`, `epfl-ssh` shell functions; needs openconnect + keepassxc + macOS Keychain) | `true` on macOS, `false` on Linux/Windows |
| `personal_mcps` | Claude MCP servers: `moodle` + `edstem` (EPFL-specific) | `true` on macOS, `false` elsewhere |
| `work_mcps` | Claude MCP servers: `atlassian` (Jira/Confluence) + `slack` (stealth) | `false` everywhere (opt-in for Citadel etc.) |

**Flip a toggle later** without re-running init:

```bash
# Edit the resolved config
$EDITOR ~/.config/chezmoi/chezmoi.toml      # set epfl_vpn = false (or true)
chezmoi apply                                # chezmoi removes/adds the file
```

**Re-prompt cleanly** (forgets previous answers):

```bash
chezmoi init --force                         # re-runs the prompt
```

## Claude Code MCP servers

MCP server definitions live in `dot_claude/mcp-servers/*.json.tmpl`. Each
template renders a stdio MCP definition; the reconciliation script
(`run_onchange_claude_mcp_setup.sh.tmpl`) reads them and calls
`claude mcp add-json -s user` to apply. Orphans (server present in
`~/.claude/mcp-servers/.last-applied` but no longer on disk) are removed.

### Architecture choices

- **No source-repo clones.** Both personal MCPs (`moodle`, `edstem`) run via
  `uvx --from git+ssh://github.com/.../...` — uv handles the install/cache
  invisibly. The work MCPs use `uvx` against PyPI (`mcp-atlassian`) and
  `npx` against npm (`slack-mcp-server`). All four are single-line definitions.
- **Secrets — macOS:** `keepassxcAttribute` reads the entry at apply time.
- **Secrets — Linux/Windows:** captured by `promptStringOnce` at `chezmoi init`,
  persisted in `~/.config/chezmoi/chezmoi.toml` (mode 0600, never committed).
  For corp environments swap this for chezmoi `[secret]` + a vault command.

### Required KeePassXC entries (macOS, when the relevant flag is on)

| Flag | Entry | Fields |
|---|---|---|
| `personal_mcps` | `Claude/moodle` | URL = `moodle.epfl.ch` (no protocol), Password = Moodle API token |
| `personal_mcps` | `Claude/edstem` | Password = Ed API token, URL = `eu` or `us` (region; URL field used because keepassxc-cli 2.7.x can't write custom strings) |
| `work_mcps` (if you run macOS Citadel-like) | `Claude/atlassian` | URL = `https://yourorg.atlassian.net`, UserName = email, Password = API token |
| `work_mcps` (if you run macOS Citadel-like) | `Claude/slack` | Custom strings `xoxc_token` and `xoxd_token` (from Slack web devtools) |

### Bootstrap order (first machine setup)

```bash
# 1. Clone chezmoi source
chezmoi init eliemada/dotfiles

# 2. Create KeePassXC entries (macOS) or prepare to paste secrets at init prompts (other)

# 3. Apply — KeePassXC may prompt for master password once per session
chezmoi apply
```

### Adding a new MCP server

```bash
# 1. Create dot_claude/mcp-servers/<name>.json.tmpl (use existing as template)
# 2. If it needs secrets on non-macOS, add prompts in .chezmoi.toml.tmpl
# 3. chezmoi apply  — reconciliation script picks it up
```

### Removing an MCP server

```bash
# 1. Delete dot_claude/mcp-servers/<name>.json.tmpl
# 2. chezmoi apply  — orphan detection removes it via `claude mcp remove`
```
