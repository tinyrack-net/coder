# Headless Wayland + ibus-hangul reproduction container for the probe app.
# Covers the GTK_IM_MODULE=ibus direct path only; the GNOME text-input-v3
# path cannot be built from sway + ibus (ibus does not speak input-method-v2).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl xz-utils unzip zip git ca-certificates \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
    sway wtype grim \
    ibus ibus-gtk3 ibus-hangul \
    dbus dconf-cli dconf-service dconf-gsettings-backend libglib2.0-bin \
    xkb-data file iso-codes x11-xkb-utils \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m prober && git config --system --add safe.directory '*'

# Both dconf.xml and memconf.xml claim org.freedesktop.IBus.Config; when
# memconf wins the race the engine sees empty settings and ibus-hangul
# silently starts in Latin mode. Force the dconf backend.
RUN rm /usr/share/ibus/component/memconf.xml

# Same Flutter version as the developer machine (3.44.9 stable). Owned by
# the build user so `flutter` can populate bin/cache.
RUN curl -fsSL -o /tmp/flutter.tar.xz \
      https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.9-stable.tar.xz \
  && mkdir -p /sdks \
  && tar -xJf /tmp/flutter.tar.xz -C /sdks \
  && rm /tmp/flutter.tar.xz \
  && chown -R prober:prober /sdks/flutter
ENV PATH="$PATH:/sdks/flutter/bin"

# Separate layer: CJK glyphs for screenshot evidence only.
RUN apt-get update && apt-get install -y --no-install-recommends fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*

# wlkey: keymap-faithful virtual-keyboard injector (see wlkey.c for why
# wtype cannot be used with ibus-hangul).
RUN apt-get update && apt-get install -y --no-install-recommends \
    libwayland-dev libwayland-bin libxkbcommon-dev \
  && rm -rf /var/lib/apt/lists/*
COPY virtual-keyboard-unstable-v1.xml /tmp/vk.xml
COPY wlkey.c /tmp/wlkey.c
RUN cd /tmp \
  && wayland-scanner private-code vk.xml vk-protocol.c \
  && wayland-scanner client-header vk.xml vk-client.h \
  && cc -O2 wlkey.c vk-protocol.c -o /usr/local/bin/wlkey \
     -lwayland-client -lxkbcommon

COPY gtk_probe.c /gtk_probe.c
RUN cc /gtk_probe.c -o /usr/local/bin/gtk_probe $(pkg-config --cflags --libs gtk+-3.0)

COPY probe_entry.sh /probe_entry.sh
COPY probe_inner.sh /probe_inner.sh
RUN chmod +x /probe_entry.sh /probe_inner.sh && sed -i 's/\r$//' /probe_entry.sh /probe_inner.sh

ENTRYPOINT ["/probe_entry.sh"]
