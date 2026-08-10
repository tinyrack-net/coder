#!/usr/bin/env bash
# Native-Wayland sibling of run_linux_ibus_terminal_e2e.sh: boots a headless
# sway session, starts ibus-daemon over D-Bus (no XIM), and drives real
# ibus-hangul into the embedded PTY through wlkey's virtual keyboard.
# Reproduces the syllable-reorder path that the X11 harness cannot reach.
set -euo pipefail

artifact_dir="${GITHUB_WORKSPACE:-$(pwd)}/ibus-terminal-wayland-artifacts"
mkdir -p "$artifact_dir"

sway_pid=""
capture_failure() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    ibus engine >"$artifact_dir/engine.txt" 2>&1 || true
    gsettings list-recursively org.freedesktop.ibus.engine.hangul \
      >"$artifact_dir/config.txt" 2>&1 || true
    swaymsg -t get_tree >"$artifact_dir/windows.json" 2>&1 || true
    od -An -tx1 "$artifact_dir/pty-input.bin" \
      >"$artifact_dir/pty-bytes.txt" 2>&1 || true
    grim "$artifact_dir/failure.png" 2>/dev/null || true
  fi
  [[ -n $sway_pid ]] && kill "$sway_pid" 2>/dev/null || true
  exit "$status"
}
trap capture_failure EXIT

# Mirror the X11 harness engine configuration. When the reporter's captured
# gsettings differ (notably preedit-mode), update both harnesses together.
gsettings set org.freedesktop.ibus.engine.hangul hangul-keyboard '2'
gsettings set org.freedesktop.ibus.engine.hangul initial-input-mode 'hangul'
gsettings set org.freedesktop.ibus.engine.hangul disable-latin-mode false
gsettings set org.freedesktop.ibus.engine.hangul preedit-mode 'syllable'
gsettings set org.freedesktop.ibus.engine.hangul word-commit false
gsettings set org.freedesktop.ibus.engine.hangul switch-keys 'Shift+space'
gsettings set org.freedesktop.ibus.engine.hangul on-keys 'Hangul'

# Key injection: build wlkey, a virtual-keyboard-v1 client that uploads the
# standard kr layout and sends true evdev keycodes. wtype cannot be used:
# ibus-hangul re-derives the keysym from the KEYCODE against a built-in US
# keymap (position-based input), and wtype's compact synthetic keycodes
# decode as garbage there, so every key passes through uncomposed.
wlkey_dir="$(mktemp -d)"
wayland-scanner private-code tool/wlkey/virtual-keyboard-unstable-v1.xml \
  "$wlkey_dir/vk-protocol.c"
wayland-scanner client-header tool/wlkey/virtual-keyboard-unstable-v1.xml \
  "$wlkey_dir/vk-client.h"
cc -O2 -I"$wlkey_dir" tool/wlkey/wlkey.c "$wlkey_dir/vk-protocol.c" \
  -o "$wlkey_dir/wlkey" -lwayland-client -lxkbcommon
export TINYRACK_WLKEY="$wlkey_dir/wlkey"

sway_config="$(mktemp)"
cat >"$sway_config" <<'SWAY'
output HEADLESS-1 resolution 1920x1080
SWAY
WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
  sway -c "$sway_config" &
sway_pid=$!

wayland_socket=""
for _ in $(seq 1 100); do
  for candidate in "$XDG_RUNTIME_DIR"/wayland-*; do
    [[ -S $candidate ]] && wayland_socket="$(basename "$candidate")"
  done
  [[ -n $wayland_socket ]] && break
  sleep 0.1
done
[[ -n $wayland_socket ]]
export WAYLAND_DISPLAY="$wayland_socket"
SWAYSOCK="$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -1)"
export SWAYSOCK

# No --xim: GTK talks to ibus directly over D-Bus (GTK_IM_MODULE=ibus in the
# caller's environment), which is the Wayland path under test.
ibus-daemon --daemonize
# `ibus engine hangul` can exit non-zero (its setxkbmap helper is absent on
# Wayland) while the switch still lands, so judge readiness by state.
engine_ready=false
for _ in $(seq 1 50); do
  if [[ $(ibus engine 2>/dev/null) == hangul ]]; then
    engine_ready=true
    break
  fi
  ibus engine hangul >/dev/null 2>&1 || true
  sleep 0.2
done
[[ $engine_ready == true ]]

export TINYRACK_IBUS_ARTIFACT_DIR="$artifact_dir"
flutter pub get --enforce-lockfile
cd packages/app
flutter test integration_test/terminal_ibus_wayland_e2e_test.dart -d linux
