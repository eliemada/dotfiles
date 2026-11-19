# Dotfiles (chezmoi)

One repo, two real profiles:

| | **Mac** (personal) | **Linux** (work, e.g. QRT) |
|---|---|---|
| Shell (zsh + oh-my-zsh, starship, aliases, functions) | ✓ | ✓ |
| Modern CLI tools (eza, bat, fzf, rg, zoxide, atuin, delta, lazygit, …) | Brewfile | Brewfile.linux |
| herdr + `hwt`, Claude Code, skills, rules, plugins | ✓ | ✓ |
| Daily auto-update of Claude + skills + plugins | launchd | systemd timer (cron fallback) |
| Git aliases / defaults | ✓ | ✓ |
| Git identity | personal, per remote | work email asked at `chezmoi init` |
| GUI apps, Ghostty, macOS defaults, Dock | ✓ | — |
| KeePassXC, personal GitHub/GitLab keys, personal MCPs, EPFL VPN | ✓ | — |
| Servers / internal hosts | `~/.ssh/config.d/*` — local, never in this repo | same |

Windows is still supported (PowerShell profile + Scoop) but not actively used.

> **Rule of thumb:** don't edit `~/.zshrc`, `~/.gitconfig`, … directly. Use `chezmoi edit <file>`,
> or `chezmoi re-add <file>` after a live edit. Machine-only tweaks go in `~/.bash_extras`
> (untracked); machine-only SSH hosts in `~/.ssh/config.d/<name>` (untracked).

## New machine

**Mac**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi keepassxc
chezmoi init --apply eliemada/dotfiles      # KeePassXC asks for the master password
```

**Linux (QRT)** — needs sudo for the first run only (apt packages + login shell):
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply eliemada/dotfiles
# asks: name, git email (use the work address), feature flags (answer no)
exec zsh
```
The first apply: installs apt basics + zsh (script 00) → Linuxbrew + tools (10) → codex/gemini
(20) → rtk (30) → enables the daily updater, whose first run installs GSD + skills (70).

> Before installing AI tooling on a work machine, check the employer's policy on which tools
> may see internal code. Nothing from a work machine is synced back into this repo.

## Claude Code on both machines

**What is shared (via this repo):** `CLAUDE.md`, `RTK.md`, `settings.json`, `rules/`, hooks,
own skills, the skill-package list, herdr config. Same agent behaviour everywhere.

**What is NOT shared:** sessions/history (`~/.claude/projects`), credentials, MCP secrets.
Each machine logs in to Claude Code itself.

**Daily updater** — `~/.local/bin/claude-update` (log: `~/.local/state/claude-update.log`):
1. Claude Code binary + `stop-slop` (chezmoi externals, from GitHub releases)
2. skill packages in `~/.config/claude-update/skills.txt` — installs missing, updates all
3. own skills that are git clones (`git pull --ff-only`)
4. GSD (`get-shit-done-cc`); its rewrite of hook paths in settings.json is undone
5. plugin marketplaces + every installed plugin

Run it by hand anytime: `claude-update --verbose`. Restart Claude Code afterwards.
Add a skill package: append a line to `dot_config/claude-update/skills.txt`.
After changing settings with `/config` or installing a plugin: `claude-settings-capture`, then commit.

**Working across Mac + remote Linux (herdr):**
- Run herdr on each machine. On the remote one: `ssh <host> -t herdr` — the herdr server keeps
  agents running when the SSH connection drops; reattach with the same command.
- Or use the herdr desktop app (`brew install --cask herdr-app`), which shows local and SSH
  machines' spaces and agents in one window.
- `claude --remote-control` exposes a session to claude.ai / the mobile app.
- New worktree + agent in one go: `hwt <branch> [task]` (or `prefix+t` in herdr).

## Layout

```
.chezmoi.toml.tmpl          prompts (name, email), feature flags, KeePassXC (Mac)
.chezmoiignore              what each OS / flag skips (patterns match TARGET paths)
.chezmoiexternal.toml.tmpl  downloads: oh-my-zsh + plugins, claude binary, nerd font (Linux), stop-slop
.chezmoiremove              stale targets deleted after renames
.chezmoiscripts/            run scripts, in NN order (table below)

dot_zshrc, dot_bashrc       thin: oh-my-zsh, then ~/.shrc.d/*, then zoxide
dot_bash_profile            login bash → zsh when chsh isn't allowed (LDAP accounts)
dot_shrc.d/                 ALL shared shell config, filename order, bash AND zsh
  00-git-aliases.sh.pre  01-homebrew.sh.pre      (before oh-my-zsh)
  10-functions  20-23 aliases (core, system, dev, paths)  30-local (~/.bash_extras)
  50-env-tools  55-toolchains  60-git-ai
  61-claude-abl  65-tactics-r2  70-epfl-vpn     (Mac / flag only)

dot_config/                 herdr (template), zed, atuin, gh, git, starship, eza, fzf, carapace,
                            claude-update/skills.txt, systemd/user (Linux)
private_Library/            Ghostty config, LaunchAgents (Mac)
dot_local/bin/              hwt, claude-update, claude-settings-capture
dot_claude/                 CLAUDE.md, RTK.md, settings.json.tmpl, rules/, hooks/, skills/, mcp-servers/
private_dot_ssh/config.tmpl defaults + Include ~/.ssh/config.d/*; personal git keys on Mac only
dot_gitconfig.tmpl          aliases/defaults everywhere; personal per-remote identities on Mac only
dot_Brewfile, dot_Brewfile.linux
```

### Scripts

| # | Script | Runs | OS |
|---|---|---|---|
| before-00 | linux-system: apt basics, zsh login shell | once | Linux |
| 05 | scoop-install | Scoopfile changes | Windows |
| 10 | brew-bundle (installs Homebrew if missing) | a Brewfile changes | Mac, Linux |
| 20 | install-cli-tools: codex, gemini-cli (npm) | once | Mac, Linux |
| 30 | rtk-setup | rtk version changes | all |
| 40 | claude-mcp-setup | MCP definitions change | all |
| 50 / 55 | macos-defaults / macos-dock | once | Mac |
| 60 | linux-font-cache | font changes | Linux |
| after-10 | ssh-key-restore (KeePassXC) | once | Mac |
| after-70 | claude-update-schedule (+ first run) | unit files change | Mac, Linux |

Run-state is keyed by content hash: renaming a script doesn't re-run it, editing it does.

## Feature flags

Asked once at `chezmoi init`, stored in `~/.config/chezmoi/chezmoi.toml`
(edit + `chezmoi apply`, or `chezmoi init --force` to re-ask).

| Flag | Installs | Default |
|---|---|---|
| `epfl_vpn` | `~/.shrc.d/70-epfl-vpn.sh` | Mac: on |
| `personal_mcps` | MCP servers `moodle`, `edstem` (KeePassXC) | Mac: on |
| `work_mcps` | MCP servers `atlassian`, `slack` | off |

### MCP servers

`dot_claude/mcp-servers/*.json.tmpl`; script 40 applies them with `claude mcp add-json -s user`
and removes orphans. Secrets: KeePassXC on Mac (`Claude/<name>` entries), `promptStringOnce`
elsewhere (stored only in the local chezmoi.toml).

## Packages

- Mac: `dot_Brewfile` (sectioned). Drift check: `brew bundle check --file="$(chezmoi source-path)/dot_Brewfile"`
- Linux: `dot_Brewfile.linux`. Windows: `dot_config/scoop/Scoopfile.json`.

## Everyday commands

```bash
chezmoi diff / apply          # preview / apply (KeePassXC templates need a real terminal)
chezmoi edit --apply FILE     # edit source + apply
chezmoi re-add FILE           # capture a live edit
chezmoi add FILE              # start managing a file
chezmoi unmanaged ~/.config   # configs not tracked yet
chezmoi update                # git pull + apply (do this on the Linux box to get Mac changes)
chezmoi cd                    # go to the repo to commit/push
```
