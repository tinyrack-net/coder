#!/usr/bin/env bash
# Environment facts that decide which IME path the bug lives on.
# Run on the Ubuntu Wayland machine; paste the whole output back.
set -u

echo "== session =="
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE-}"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY-}"
echo "GDK_BACKEND=${GDK_BACKEND-}"
echo "GTK_IM_MODULE=${GTK_IM_MODULE-}"
echo "QT_IM_MODULE=${QT_IM_MODULE-}"
echo "XMODIFIERS=${XMODIFIERS-}"
echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP-}"

echo "== versions =="
gnome-shell --version 2>/dev/null || true
mutter --version 2>/dev/null | head -1 || true
ibus version 2>/dev/null || true
dpkg -l ibus ibus-hangul libgtk-3-0t64 libgtk-3-0 2>/dev/null | grep '^ii' || true
flutter --version 2>/dev/null | head -2 || true

echo "== ibus-hangul settings =="
gsettings list-recursively org.freedesktop.ibus.engine.hangul 2>/dev/null || true
echo "current engine: $(ibus engine 2>/dev/null || echo '?')"

echo "== XWayland check =="
echo "Start the Coder app (and/or the probe) FIRST, then run this script."
echo "Anything listed below runs on XWayland, not native Wayland:"
xlsclients 2>/dev/null || echo "(xlsclients missing — sudo apt install x11-utils)"
