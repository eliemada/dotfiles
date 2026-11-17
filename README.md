# Dotfiles (chezmoi)

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io): **macOS** (main), **Linux**, **Windows**.

> **Rule of thumb:** never edit `~/.zshrc`, `~/.ssh/config`, etc. directly. Edit with
> `chezmoi edit <file>` or capture a change with `chezmoi re-add <file>`. Per-machine
> tweaks that should *not* be shared go in `~/.bash_extras` (untracked, sourced by `30-local.sh`).

## New machine

```bash
# macOS: install Homebrew first, then
brew install chezmoi age keepassxc

# 1. Restore the age key (decrypts private SSH hosts). Without it, encrypted
#    files are skipped, not fatal.
mkdir -p ~/.config/chezmoi
keepassxc-cli attachment-export ~/Dropbox/PW.kdbx config/chezmoi/age-key key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 2. Init (asks name/email + feature flags once) and apply
chezmoi init --apply eliemada/dotfiles
```

Linux: same, with `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply eliemada/dotfiles`.
Windows: `scoop install chezmoi; chezmoi init --apply eliemada/dotfiles`.

## Layout

```
.chezmoi.toml.tmpl          config: age encryption, prompts, feature flags, KeePassXC
.chezmoiignore              what is skipped per OS / per flag (patterns match TARGET paths)
.chezmoiexternal.toml.tmpl  things chezmoi downloads: oh-my-zsh + plugins, claude binary,
                            nerd font (Linux), stop-slop skill
.chezmoiremove              stale targets deleted after renames
.chezmoiscripts/            run scripts, executed in NN order (see below)
.chezmoitemplates/          shared template snippets (KeePassXC MCP secrets)

dot_zshrc, dot_bashrc       thin: oh-my-zsh, then source ~/.shrc.d/*, then zoxide
dot_shrc.d/                 ALL shared shell config, sourced in filename order by bash AND zsh
  00-git-aliases.sh.pre       loaded before oh-my-zsh
  10-functions.sh             extract, mkcd, update, cb, ...
  20-aliases-core.sh          better defaults, navigation, files, time
  21-aliases-system.sh        network, power, sysadmin, macOS
  22-aliases-dev.sh           applications, development
  23-aliases-paths.sh         path/config shortcuts, misc
  30-local.sh                 sources ~/.bash_extras (machine-local, untracked)
  50-env-tools.sh             env vars, eza/bat/fzf/atuin/starship init
  55-toolchains.sh            bun, Run:ai
  60-git-ai.sh  61-claude-abl.sh  65-tactics-r2.sh
  70-epfl-vpn.sh              only if epfl_vpn = true

dot_config/                 ~/.config: herdr, zed, atuin, gh, git, starship, eza, fzf,
                            carapace, scoop (Windows)
private_Library/…/com.mitchellh.ghostty/config   Ghostty (macOS)
dot_local/bin/              personal scripts (hwt: herdr worktree + agent)
dot_claude/                 Claude Code: CLAUDE.md, RTK.md, settings.json, rules/, hooks/,
                            own skills/, mcp-servers/
private_dot_ssh/
  config.tmpl                 public defaults + GitHub/GitLab/EPFL HPC
  private_config.d/encrypted_private_hosts.age   servers, IPs, accounts (age)
dot_gitconfig*.tmpl         git + per-remote identities (github, gitlab, madauto)
dot_Brewfile(.linux)        Homebrew packages
Documents/PowerShell/       Windows profile
```

### Scripts (`.chezmoiscripts/`)

| # | Script | When | OS |
|---|---|---|---|
| 05 | scoop-install | Scoopfile changes | Windows |
| 10 | brew-bundle | **any Brewfile changes** (hash embedded) | macOS, Linux |
| 20 | install-cli-tools | once | macOS, Linux |
| 30 | rtk-setup | rtk version changes | all |
| 40 | claude-mcp-setup | MCP definitions change | all |
| 50 | macos-defaults | once | macOS |
| 55 | macos-dock | once | macOS |
| 60 | linux-font-cache | font changes | Linux |
| after-10 | ssh-key-restore (KeePassXC) | once | macOS |

Script run-state is keyed by content hash, so renaming a script does not re-run it.

## Secrets

Two mechanisms, nothing secret is committed in plain text (the repo is **public**):

| What | How | Edit |
|---|---|---|
| SSH hosts, server IPs, accounts | age-encrypted file in repo | `chezmoi edit ~/.ssh/config.d/hosts` |
| SSH key paths, MCP tokens | KeePassXC at apply time (`keepassxcAttribute`) | KeePassXC |
| Project credentials (R2, abliteration) | read at call time from untracked `.env` files | the project |

Add a new private file: `chezmoi add --encrypt <file>`.
The age **public** key is in `.chezmoi.toml.tmpl`; the **private** key is only in
`~/.config/chezmoi/key.txt` and KeePassXC entry `config/chezmoi/age-key`.

## Feature flags

Asked once at `chezmoi init`, stored in `~/.config/chezmoi/chezmoi.toml`. Change by editing
that file and running `chezmoi apply`, or re-prompt with `chezmoi init --force`.

| Flag | Installs | Default |
|---|---|---|
| `epfl_vpn` | `~/.shrc.d/70-epfl-vpn.sh` (`epfl`, `epfl-ssh`) | macOS: on |
| `personal_mcps` | Claude MCP servers `moodle`, `edstem` | macOS: on |
| `work_mcps` | Claude MCP servers `atlassian`, `slack` | off |

## Claude Code

Tracked here: `CLAUDE.md`, `RTK.md`, `settings.json` (template, `$HOME` substituted),
`rules/`, `hooks/herdr-agent-state.sh`, own skills (`apple-design`, `asd-ste100`,
`docling-pdf`, `pdf-typst-diff`, `reverse-engineer-anything`), MCP definitions.
`stop-slop` comes from its upstream repo via `.chezmoiexternal`.

**Not tracked** (reinstall with their own installer on a new machine):

```bash
npx get-shit-done-cc@latest          # GSD: gsd-* skills, agents, hooks
npx skills add mattpocock/skills     # mattpocock skills (lock: ~/.agents/.skill-lock.json)
# impeccable: ships a platform binary, install from its upstream
# plugins: listed in settings.json, Claude Code installs them on start
```

Claude Code rewrites `settings.json` itself (`/config`, `/model`, plugin installs). Capture
those changes back into the template (plain `re-add` does not work on templates):

```bash
sed "s|$HOME|{{ .chezmoi.homeDir }}|g" ~/.claude/settings.json \
  > "$(chezmoi source-path)/dot_claude/settings.json.tmpl"
```

### MCP servers

Definitions live in `dot_claude/mcp-servers/*.json.tmpl`; script 40 applies them with
`claude mcp add-json -s user` and removes orphans. Secrets: KeePassXC on macOS,
`promptStringOnce` at init elsewhere (stored in the local, uncommitted chezmoi.toml).

| Flag | KeePassXC entry | Fields |
|---|---|---|
| `personal_mcps` | `Claude/moodle` | URL = `moodle.epfl.ch`, Password = API token |
| `personal_mcps` | `Claude/edstem` | Password = API token, URL = `eu` / `us` |
| `work_mcps` | `Claude/atlassian` | URL, UserName = email, Password = API token |
| `work_mcps` | `Claude/slack` | custom strings `xoxc_token`, `xoxd_token` |

Add one: create `dot_claude/mcp-servers/<name>.json.tmpl`, `chezmoi apply`.
Remove one: delete the file, `chezmoi apply`.

## Packages

- macOS: `dot_Brewfile` (sectioned). After `brew install x`, add it to the right section.
  Check drift: `brew bundle check --file="$(chezmoi source-path)/dot_Brewfile"`.
- Linux: `dot_Brewfile.linux` (CLI only). Windows: `dot_config/scoop/Scoopfile.json`.

## Everyday commands

```bash
chezmoi status / diff        # what would change (KeePassXC templates need a real terminal)
chezmoi apply                # apply everything
chezmoi edit --apply FILE    # edit source + apply
chezmoi re-add FILE          # capture a live edit back into the source
chezmoi add [--encrypt] FILE # start managing a file
chezmoi unmanaged ~/.config  # find configs not yet tracked
chezmoi cd                   # jump to the source repo (commit + push from there)
```

## RTK (Rust Token Killer)

`rtk` (Homebrew; GitHub release on Windows) proxies shell output to cut LLM tokens.
Script 30 runs `rtk init -g` for Claude Code and Codex; it embeds `rtk --version`, so a
`brew upgrade rtk` re-runs it. Windows: bump `$DesiredVersion` in the `.ps1.tmpl`.
