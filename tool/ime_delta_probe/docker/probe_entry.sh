#!/bin/bash
# Copies the mounted probe source (/src, read-only) into the container
# filesystem, builds the Linux bundle, then runs the Wayland+ibus session as
# the non-root user (sway declines to run as root).
set -euxo pipefail

cp -r /src /home/prober/probe
rm -rf /home/prober/probe/{build,.dart_tool,linux,traces,docker}
mkdir -p /out
chown -R prober:prober /home/prober/probe /out

# /cache (optional volume) keeps the built bundle across runs so harness
# iterations skip the multi-minute Flutter build when main.dart is unchanged.
if [[ -d /cache/bundle ]] && cmp -s /src/lib/main.dart /cache/main.dart.built; then
  mkdir -p /home/prober/probe/build/linux/x64/release
  cp -r /cache/bundle /home/prober/probe/build/linux/x64/release/bundle
  chown -R prober:prober /home/prober/probe
else
  su -s /bin/bash prober -c '
    set -euxo pipefail
    export HOME=/home/prober
    export PATH="$PATH:/sdks/flutter/bin"
    cd /home/prober/probe
    flutter create --platforms=linux --project-name ime_delta_probe .
    flutter pub get
    flutter build linux --release
  '
  if [[ -d /cache ]]; then
    rm -rf /cache/bundle
    cp -r /home/prober/probe/build/linux/x64/release/bundle /cache/bundle
    cp /src/lib/main.dart /cache/main.dart.built
  fi
fi

exec su -s /bin/bash prober -c '
  export HOME=/home/prober
  export XDG_RUNTIME_DIR=/tmp/xdg
  mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
  exec dbus-run-session -- /probe_inner.sh
'
