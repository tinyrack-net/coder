#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${GITHUB_WORKSPACE:-$(pwd)}/ibus-terminal-artifacts"
mkdir -p "$artifact_dir"

capture_failure() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    ibus engine >"$artifact_dir/engine.txt" 2>&1 || true
    gsettings list-recursively org.freedesktop.ibus.engine.hangul \
      >"$artifact_dir/config.txt" 2>&1 || true
    xdotool getactivewindow getwindowname \
      >"$artifact_dir/active-window.txt" 2>&1 || true
    xwininfo -root -tree >"$artifact_dir/windows.txt" 2>&1 || true
    od -An -tx1 "$artifact_dir/pty-input.bin" \
      >"$artifact_dir/pty-bytes.txt" 2>&1 || true
    scrot "$artifact_dir/failure.png" || true
  fi
  exit "$status"
}
trap capture_failure EXIT

gsettings set org.freedesktop.ibus.engine.hangul hangul-keyboard '2'
gsettings set org.freedesktop.ibus.engine.hangul initial-input-mode 'hangul'
gsettings set org.freedesktop.ibus.engine.hangul disable-latin-mode false
gsettings set org.freedesktop.ibus.engine.hangul preedit-mode 'syllable'
gsettings set org.freedesktop.ibus.engine.hangul word-commit false
gsettings set org.freedesktop.ibus.engine.hangul switch-keys 'Shift+space'
gsettings set org.freedesktop.ibus.engine.hangul on-keys 'Hangul'

ibus-daemon --daemonize --xim
engine_ready=false
for _ in $(seq 1 50); do
  if ibus list-engine | grep -q 'hangul - Hangul' &&
    ibus engine hangul >/dev/null 2>&1 &&
    [[ $(ibus engine 2>/dev/null) == hangul ]]; then
    engine_ready=true
    break
  fi
  sleep 0.2
done
[[ $engine_ready == true ]]

export TINYRACK_IBUS_ARTIFACT_DIR="$artifact_dir"
mise exec -- flutter pub get --enforce-lockfile
cd apps/coder_app
mise exec -- flutter test integration_test/terminal_ibus_e2e_test.dart -d linux
