#!/usr/bin/env bash
################################################################################
# Global AI CLIs via npm (run once): OpenAI Codex. Claude Code itself is NOT installed here:
# chezmoi downloads the official binary (.chezmoiexternal.toml.tmpl).
################################################################################
set -uo pipefail
. "$HOME/.shrc.d/01-homebrew.sh.pre" 2>/dev/null || true   # fresh Linux: brew not on PATH yet
. "$HOME/.shrc.d/02-mirrors.sh.pre" 2>/dev/null || true   # npm registry mirror

if ! command -v npm >/dev/null 2>&1; then
  echo "install-cli-tools: npm not found (brew \"node\" missing?); skipping"; exit 0
fi
npm install -g @openai/codex || echo "install-cli-tools: npm install failed"
