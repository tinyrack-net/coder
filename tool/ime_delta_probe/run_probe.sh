#!/usr/bin/env bash
# Runs the probe once per IM path and collects traces under ./traces/.
# Usage: ./run_probe.sh <run-name>   e.g. ./run_probe.sh wayland-default
# In each run: focus the terminal, switch to Hangul, type 안녕하세요.
# once SLOWLY (1 key/second) and once FAST, press Enter after each,
# then close the window.
set -euo pipefail

name="${1:?usage: ./run_probe.sh <run-name>}"
out="$(pwd)/traces/$name"
mkdir -p "$out"

case "$name" in
  wayland-default)
    # The real user path: GNOME decides the IM module (text-input-v3 when
    # GTK_IM_MODULE is unset).
    env -u GDK_BACKEND IME_TRACE_DIR="$out" flutter run -d linux --release
    ;;
  wayland-ibus)
    # Force the direct ibus D-Bus path on Wayland.
    env -u GDK_BACKEND GTK_IM_MODULE=ibus IME_TRACE_DIR="$out" \
      flutter run -d linux --release
    ;;
  x11-control)
    # Control run: should produce clean 안녕하세요. if the bug is Wayland-only.
    GDK_BACKEND=x11 GTK_IM_MODULE=ibus IME_TRACE_DIR="$out" \
      flutter run -d linux --release
    ;;
  *)
    IME_TRACE_DIR="$out" flutter run -d linux --release
    ;;
esac

echo
echo "== $name: pty bytes =="
od -An -tx1 "$out/pty-input.bin" 2>/dev/null || echo "(no pty-input.bin)"
echo "== $name: decoded =="
cat "$out/pty-input.bin" 2>/dev/null; echo
echo "trace: $out/ime-trace.jsonl ($(wc -l < "$out/ime-trace.jsonl" 2>/dev/null || echo 0) events)"
