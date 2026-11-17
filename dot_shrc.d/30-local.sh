################################################################################
# ~/.shrc.d/30-local.sh
# Machine-local overrides: ~/.bash_extras is NOT managed by chezmoi.
# Put per-machine aliases/exports there instead of editing ~/.zshrc.
################################################################################
# shellcheck shell=bash
[ -r "$HOME/.bash_extras" ] && . "$HOME/.bash_extras"
