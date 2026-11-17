#!/bin/bash
################################################################################
# run_once_configure-dock.sh
# Configure the macOS Dock with preferred apps (run once by chezmoi)
################################################################################

set -euo pipefail

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil is required but was not found. Install it with 'brew install dockutil'." >&2
  exit 1
fi

targets=(
  "LibreWolf:/Applications/LibreWolf.app"
  "Notes:/System/Applications/Notes.app"
  "Email:/System/Applications/Mail.app"
  "Calendar:/System/Applications/Calendar.app"
)

for target in "${targets[@]}"; do
  IFS=":" read -r label app_path <<<"${target}"

  if [[ ! -d "${app_path}" ]]; then
    echo "Skipping ${label}: ${app_path} not found." >&2
    continue
  fi

  dockutil --remove "${label}" --no-restart >/dev/null 2>&1 || true
  dockutil --add "${app_path}" --label "${label}" --no-restart
  echo "Added ${label} to the Dock."

done

# Add the Downloads folder to the Dock
downloads_path="${HOME}/Downloads"
if [[ -d "${downloads_path}" ]]; then
  dockutil --remove "${downloads_path}" --no-restart >/dev/null 2>&1 || true
  dockutil --add "${downloads_path}" \
    --view grid \
    --display folder \
    --sort dateadded \
    --section others \
    --no-restart
  echo "Added Downloads folder to the Dock."
else
  echo "Downloads folder not found at ${downloads_path}." >&2
fi

# Restart Dock once after all changes to avoid flicker.
dockutil --restart || killall Dock
