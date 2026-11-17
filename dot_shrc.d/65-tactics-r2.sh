################################################################################
# ~/.shrc.d/65-tactics-r2.sh
# tactics / justice-raw R2 browsing. Credentials come from the tactics project
# .env at call time (never stored here). `justice` opens the stu TUI.
################################################################################
# shellcheck shell=bash
# Loads R2_* from the tactics project .env, remaps to AWS_* for stu, then opens
# the TUI. Run `justice` from anywhere.
justice() {
  local env_file="$HOME/Desktop/code/tactics/.env"
  [[ -f "$env_file" ]] || { echo "missing $env_file"; return 1; }
  set -a; source "$env_file"; set +a
  AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" \
  AWS_DEFAULT_REGION=auto \
    stu -e "$R2_S3_ENDPOINT" --region auto -b "$R2_BUCKET" --path-style always "$@"
}

# rclone-based helpers against the [justice] remote
alias jls='rclone lsf justice:justice-raw'              # jls _catalog/items.parquet/
alias jtree='rclone tree justice:justice-raw'           # jtree _catalog --max-depth 2
alias jdu='rclone ncdu justice:justice-raw'             # interactive disk-usage browser
alias jsize='rclone size justice:justice-raw'           # total bytes/object count

# s5cmd against justice (fast parallel ls/cp)
js5() {
  local env_file="$HOME/Desktop/code/tactics/.env"
  [[ -f "$env_file" ]] || { echo "missing $env_file"; return 1; }
  set -a; source "$env_file"; set +a
  AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" \
  AWS_REGION=auto \
    s5cmd --endpoint-url "$R2_S3_ENDPOINT" "$@"
}
