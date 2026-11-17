################################################################################
# ~/.shrc.d/61-claude-abl.sh
# Claude Code routed through Abliteration (api.abliteration.ai).
# Plain `claude` is untouched. Key lives in ~/.config/abliteration/env (untracked).
################################################################################
# shellcheck shell=bash
claude-abl() {
  local envfile="$HOME/.config/abliteration/env"
  [[ -r $envfile ]] || { echo "claude-abl: missing $envfile" >&2; return 1; }
  if grep -q 'ak_REPLACE_ME' "$envfile"; then
    echo "claude-abl: put your ak_... key in $envfile" >&2; return 1
  fi
  ( set -a; source "$envfile"; set +a; command claude --dangerously-skip-permissions --model 'abliterated-model-large-v2[1m]' "$@" )
}
