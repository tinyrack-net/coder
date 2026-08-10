#!/bin/bash
# Runs inside dbus-run-session as the non-root user: headless sway,
# ibus-hangul, the probe app, and scripted wtype keystrokes. Artifacts land
# in /out (mounted from the host).
set -euxo pipefail

OUT=/out

collect() {
  local status=$?
  swaymsg -t get_tree >"$OUT/windows.json" 2>&1 || true
  ibus engine >"$OUT/engine.txt" 2>&1 || true
  ibus list-engine >"$OUT/engines.txt" 2>&1 || true
  ibus read-cache >"$OUT/ibus-cache.txt" 2>&1 || true
  grim "$OUT/screen.png" 2>/dev/null || true
  cp /tmp/sway.log /tmp/app.log /tmp/ibus-daemon.log "$OUT/" 2>/dev/null || true
  ps aux >"$OUT/ps.txt" 2>&1 || true
  exit "$status"
}
trap collect EXIT

gsettings set org.freedesktop.ibus.engine.hangul hangul-keyboard '2'
gsettings set org.freedesktop.ibus.engine.hangul initial-input-mode 'hangul'
gsettings set org.freedesktop.ibus.engine.hangul disable-latin-mode false
gsettings set org.freedesktop.ibus.engine.hangul preedit-mode 'syllable'
gsettings set org.freedesktop.ibus.engine.hangul word-commit false
gsettings set org.freedesktop.ibus.engine.hangul switch-keys 'Shift+space'
gsettings set org.freedesktop.ibus.engine.hangul on-keys 'Hangul'

sway_config="$(mktemp)"
echo 'output HEADLESS-1 resolution 1280x800' >"$sway_config"
WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
  sway -c "$sway_config" >/tmp/sway.log 2>&1 &

socket=""
for _ in $(seq 1 100); do
  for candidate in "$XDG_RUNTIME_DIR"/wayland-*; do
    [[ -S $candidate ]] && socket="$(basename "$candidate")"
  done
  [[ -n $socket ]] && break
  sleep 0.1
done
[[ -n $socket ]]
export WAYLAND_DISPLAY="$socket"
SWAYSOCK="$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -1)"
export SWAYSOCK
[[ -n $SWAYSOCK ]]

export IBUS_USE_PORTAL=0
ibus-daemon --verbose >/tmp/ibus-daemon.log 2>&1 &
# `ibus engine hangul` can exit non-zero (e.g. its setxkbmap helper) while
# the switch still lands, so judge readiness by the reported current engine.
ready=false
for _ in $(seq 1 50); do
  if [[ $(ibus engine 2>/dev/null) == hangul ]]; then
    ready=true
    break
  fi
  ibus engine hangul >/dev/null 2>&1 || true
  sleep 0.2
done
[[ $ready == true ]]

ibus address >"$OUT/ibus-address.txt" 2>&1 || true
dbus-monitor --address "$(ibus address)" \
  >"$OUT/ibus-bus-monitor.log" 2>&1 &
ls -la "$HOME/.config/ibus/bus" >"$OUT/ibus-bus-dir.txt" 2>&1 || true
cat /etc/machine-id /var/lib/dbus/machine-id >"$OUT/machine-id.txt" 2>&1 || true

GDK_BACKEND=wayland GTK_IM_MODULE=ibus GTK_DEBUG=modules IME_TRACE_DIR="$OUT" \
  /home/prober/probe/build/linux/x64/release/bundle/ime_delta_probe \
  >/tmp/app.log 2>&1 &

for _ in $(seq 1 100); do
  swaymsg -t get_tree | grep -q ime_delta_probe && break
  sleep 0.2
done
swaymsg -t get_tree | grep -q ime_delta_probe
sleep 2

# wlkey uploads the standard kr layout and sends true evdev keycodes.
# wtype is unusable here: ibus-hangul re-derives the keysym from the
# KEYCODE against a built-in US keymap, and wtype's compact keycodes
# decode as garbage, so every key passes through unprocessed.
type_sequence() {
  local gap_ms="$1"
  shift
  wlkey -g "$gap_ms" "$@"
}

rm -f "$OUT/pty-input.bin"

# on-keys is configured as 'Hangul', which forces Hangul mode ON (it is not
# a toggle), so each round starts from a known engine mode with no guessing.
round() {
  # Hangul (on-keys: forces Hangul mode ON, not a toggle) leads each round
  # so the engine mode is deterministic.
  type_sequence "$1" Hangul d k s s u d g k t p d y period space
  sleep 1
}

round 150
cp "$OUT/pty-input.bin" "$OUT/pty-slow.bin"
round 10
sleep 1

# Control experiment: same session, plain GTK3 entry instead of Flutter.
pkill -f ime_delta_probe || true
sleep 1
GDK_BACKEND=wayland GTK_IM_MODULE=ibus \
  gtk_probe >"$OUT/gtk-probe.log" 2>&1 &
gtk_pid=$!
for _ in $(seq 1 50); do
  swaymsg -t get_tree | grep -q gtk_probe && break
  sleep 0.2
done
sleep 2
type_sequence 150 Hangul d k s s u d g k t p d y period space
sleep 1
grim "$OUT/gtk-probe.png" 2>/dev/null || true
kill "$gtk_pid" 2>/dev/null || true

echo '== slow round ==' | tee "$OUT/result.txt"
od -An -tx1 "$OUT/pty-slow.bin" | tee -a "$OUT/result.txt"
cat "$OUT/pty-slow.bin" | tee -a "$OUT/result.txt"; echo | tee -a "$OUT/result.txt"
echo '== both rounds ==' | tee -a "$OUT/result.txt"
od -An -tx1 "$OUT/pty-input.bin" | tee -a "$OUT/result.txt"
cat "$OUT/pty-input.bin" | tee -a "$OUT/result.txt"; echo | tee -a "$OUT/result.txt"
echo '== gtk control ==' | tee -a "$OUT/result.txt"
tail -5 "$OUT/gtk-probe.log" | tee -a "$OUT/result.txt" || true
