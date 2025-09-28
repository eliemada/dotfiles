# Dotfiles (chezmoi)

These are my personal dotfiles managed with `chezmoi`. They are organized with clear, readable section headers using 80-`#` lines for quick scanning in editors.

## Quick Start

- Install chezmoi: `brew install chezmoi` (macOS) or see https://www.chezmoi.io
- Initialize from this directory: run inside this repo or `chezmoi init --source ~/.local/share/chezmoi`
- Apply configs: `chezmoi apply`

## Structure

- `dot_zshrc`: Zsh + Oh My Zsh setup, plugins, includes
- `dot_bashrc`: Bash startup that sources shared snippets and includes
- `dot_bash_aliases`: Common aliases grouped by purpose
- `dot_bash_functions`: Utility functions (extract, mkcd, update, etc.)
- `dot_shrc.d/`: Cross‑shell snippets loaded by Bash and Zsh
- `dot_Brewfile`: Homebrew taps, formulae and casks (used by `brew bundle --global`)
- `dot_gitconfig.tmpl`: Global Git config with conditional includes
- `dot_gitignore_global`: Global Git ignore patterns
- `private_dot_ssh/config.tmpl`: SSH hosts, keys resolved via KeePassXC
- `dot_config/starship/starship.toml.tmpl`: Starship prompt config
- `dot_ripgreprc`: ripgrep defaults and ignore globs
- `dot_nanorc.tmpl`: Nano configuration using a Nord palette
- `dot_pythonrc`: Interactive Python REPL tweaks
- `.chezmoi.toml.tmpl`: Chezmoi configuration and data prompts
- `run_once_configure-macos.sh`: One‑time macOS sensible defaults
- `run_onchange_brew_bundle.sh.tmpl`: Sync Homebrew from `~/.Brewfile` when it changes
- `run_once_install_cli_tools.sh`: One‑time global CLI tooling
- `run_once_after_ssh_key_restore.sh.tmpl`: Restore SSH keys from KeePassXC

## Conventions

- Section separators: 80 `#` characters frame major sections for readability.
- Shebangs stay on the first line; headers follow them.
- Template files (`*.tmpl`) use Go templates for dynamic values (e.g., Git identity, KeePassXC lookup, OS checks).

## macOS Notes

- After first apply, run_once scripts configure system defaults and bootstrap tools.
- Homebrew apps are managed by `dot_Brewfile`; changes are applied via `brew bundle --global`.

## Common Commands

- Diff desired vs actual: `chezmoi diff`
- Apply changes: `chezmoi apply` or `chezmoi apply --verbose`
- Edit and re‑apply one file: `chezmoi edit --apply <target>`

## Secrets & Keys

- SSH keys are referenced from a KeePassXC database configured in `.chezmoi.toml.tmpl`.
- The restore script (`run_once_after_ssh_key_restore.sh.tmpl`) can extract keys and add them to `ssh-agent`.

## Updating

Make changes in the source repo (this folder), commit as you like, and re‑apply with `chezmoi apply`.

