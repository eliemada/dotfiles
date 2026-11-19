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

**Linux (QRT)**: one-way, through a download mirror (Artifactory). Needs sudo on the first run only.
```bash
M=https://<artifactory>/artifactory/<github-remote>   # proxies https://github.com; or M=https://github.com

# 1. chezmoi binary + this repo, both as plain downloads (no git needed)
mkdir -p ~/.local/bin ~/.local/share/chezmoi
curl -fsSL "$M/twpayne/chezmoi/releases/latest/download/chezmoi-linux-amd64" -o ~/.local/bin/chezmoi
chmod +x ~/.local/bin/chezmoi
curl -fsSL "$M/eliemada/dotfiles/archive/HEAD.tar.gz" | tar xz --strip-components 1 -C ~/.local/share/chezmoi

# 2. init + apply. Asks: name, git email (work address), the mirror URLs below,
#    feature flags (answer no).
~/.local/bin/chezmoi init --apply
exec zsh
```
The first apply runs: apt basics + zsh (script 00), then Homebrew + tools (10), then codex (20), then rtk (30), then the daily updater, whose first run installs the skills (70).

**Updating QRT:** make changes on the Mac, push, then run `dotfiles-pull` on QRT. It uses `chezmoi update` if git
works; otherwise it downloads the repo archive through the mirror and replaces the source (the old source
is kept as `~/.local/share/chezmoi.prev`). Nothing is ever pushed from QRT, so keep machine-only tweaks in
`~/.bash_extras` and `~/.ssh/config.d/`. Never edit the source there.

### Download mirrors

Every outside fetch is built from `[data.mirror]` in `~/.config/chezmoi/chezmoi.toml` (asked on Linux;
public defaults on the Mac). Change a value, then `chezmoi apply`.

| Key | Used for | Public default |
|---|---|---|
| `github` | oh-my-zsh + plugins, skill packages, Claude binary, nerd font, Homebrew itself, this repo (`dotfiles-pull`) | `https://github.com` |
| `npm` | `npm_config_registry`: codex | public npm |
| `pypi` | `UV_INDEX_URL` / `PIP_INDEX_URL` | public PyPI |
| `brew_api` | `HOMEBREW_API_DOMAIN` (formula metadata) | formulae.brew.sh |
| `brew_bottle` | `HOMEBREW_ARTIFACT_DOMAIN` (prebuilt bottles) | ghcr.io |

Repos are fetched as `<github>/<owner>/<repo>/archive/HEAD.tar.gz` and releases as
`<github>/<owner>/<repo>/releases/...`, so the mirror only needs to proxy HTTP downloads from
github.com, not the git protocol. When `github` isn't the public URL, Homebrew is installed by
untarring `Homebrew/brew` (no git), `brew update` is disabled (upgrade = re-run the bundle), and
plugin-marketplace updates are skipped, because marketplaces are git repos.

> Before installing AI tooling on a work machine, check the employer's policy on which tools
> may see internal code. Nothing from a work machine is synced back into this repo.

## Claude Code on both machines

**What is shared (via this repo):** `CLAUDE.md`, `RTK.md`, `settings.json`, `rules/`, hooks,
own skills, the skill-package list, herdr config. Same agent behaviour everywhere.

**What is NOT shared:** sessions/history (`~/.claude/projects`), credentials, MCP secrets.
Each machine logs in to Claude Code itself.

**Daily updater** — `~/.local/bin/claude-update` (log: `~/.local/state/claude-update.log`):
1. Claude Code binary (chezmoi external, from GitHub releases)
2. skill packages in `~/.config/claude-update/skills.txt`: downloaded as archives (via the mirror), copied in
3. own skills that are git clones (`git pull --ff-only`)
4. plugin marketplaces + every installed plugin (skipped behind a mirror)

Run it by hand anytime: `claude-update --verbose`. Restart Claude Code afterwards.
Add a skill package: append a line to `dot_config/claude-update/skills.txt`.
After changing settings with `/config` or installing a plugin (on the Mac): `claude-settings-capture`, then commit and push.

**What's installed (about 40 skills, down from about 480):**
- Workflow: **superpowers** (plugin): brainstorm, plan, TDD, debug, review. It's the only workflow system;
  GSD and everything-claude-code were removed because they duplicated it.
- `mattpocock/skills` (small, sharp: grill-me, handoff, triage, tdd, code-review, ...), synced from upstream.
- Third-party single skills synced from upstream: asd-ste100, apple-design, stop-slop, reverse-engineer-anything.
- Own skills, tracked here: docling-pdf, pdf-typst-diff, plus 7 frozen mattpocock skills dropped upstream.
- Plugins on everywhere: superpowers, document-skills, astral, clangd-lsp.
- Rules: `dot_claude/rules/` (core, python, typescript). Short, with reasons, ~70 lines.

**Plugins only for some projects.** Domain plugins (travel-hacker, claude-seo, expo, sentry,
resend, ui-ux-pro-max) are installed but disabled at user level. Turn one on inside a project:
```bash
cd ~/code/my-expo-app
claude plugin enable expo@claude-plugins-official --scope project   # shared: .claude/settings.json (commit it)
claude plugin enable travel-hacker@borski --scope local             # just you: .claude/settings.local.json
```
`claude plugin list` shows what's on where. Restart Claude Code after changing.

**Working across Mac + remote Linux (herdr):**
- Run herdr on each machine. On the remote one: `ssh <host> -t herdr` — the herdr server keeps
  agents running when the SSH connection drops; reattach with the same command.
- Or use the herdr desktop app (`brew install --cask herdr-app`), which shows local and SSH
  machines' spaces and agents in one window.
- `claude --remote-control` exposes a session to claude.ai / the mobile app.
- New worktree + agent in one go: `hwt <branch> [task]` (or `prefix+t` in herdr).

## Layout

```
.chezmoi.toml.tmpl          prompts (name, email), download mirrors, feature flags, KeePassXC (Mac)
.chezmoiignore              what each OS / flag skips (patterns match TARGET paths)
.chezmoiexternal.toml.tmpl  downloads: oh-my-zsh + plugins, claude binary, nerd font (Linux)
.chezmoiremove              stale targets deleted after renames
.chezmoiscripts/            run scripts, in NN order (table below)

dot_zshrc, dot_bashrc       thin: oh-my-zsh, then ~/.shrc.d/*, then zoxide
dot_bash_profile            login bash → zsh when chsh isn't allowed (LDAP accounts)
dot_shrc.d/                 ALL shared shell config, filename order, bash AND zsh
  00-git-aliases.sh.pre  01-homebrew.sh.pre  02-mirrors.sh.pre (generated)   (before oh-my-zsh)
  10-functions  20-23 aliases (core, system, dev, paths)  30-local (~/.bash_extras)
  50-env-tools  55-toolchains  60-git-ai
  61-claude-abl  65-tactics-r2  70-epfl-vpn     (Mac / flag only)

dot_config/                 herdr (template), zed, atuin, gh, git, starship, eza, fzf, carapace,
                            claude-update/skills.txt, systemd/user (Linux)
private_Library/            Ghostty config, LaunchAgents (Mac)
dot_local/bin/              hwt, claude-update, claude-settings-capture, dotfiles-pull
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
| 20 | install-cli-tools: codex (npm) | once | Mac, Linux |
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
dotfiles-pull                 # one-way update on QRT (git if possible, else archive via mirror)
chezmoi cd                    # go to the repo to commit/push
```
