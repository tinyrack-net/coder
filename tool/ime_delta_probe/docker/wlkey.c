/* wlkey: virtual-keyboard-v1 injector with a REAL xkb layout.
 *
 * wtype builds a compact custom keymap whose keycodes do not match a
 * physical keyboard. ibus-hangul discards the delivered keysym and
 * re-derives it from the KEYCODE against a built-in US keymap
 * (position-based input), so wtype's keycodes decode as garbage and every
 * key passes through. This injector uploads the standard "kr" layout
 * (US-compatible letters plus the Hangul key) and sends true evdev
 * keycodes, so both the client and ibus-hangul agree on every key.
 *
 * Usage: wlkey [-g gap_ms] TOKEN...
 *   TOKEN = xkb keysym name ("d", "period", "space", "BackSpace",
 *           "Hangul", "Return") or "shift+NAME" for a shifted chord.
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <time.h>

#include <wayland-client.h>
#include <xkbcommon/xkbcommon.h>

#include "vk-client.h"

static struct zwp_virtual_keyboard_manager_v1 *vk_manager;
static struct wl_seat *seat;

static void registry_global(void *data, struct wl_registry *registry,
                            uint32_t name, const char *interface,
                            uint32_t version) {
  (void)data;
  (void)version;
  if (strcmp(interface, zwp_virtual_keyboard_manager_v1_interface.name) == 0) {
    vk_manager = wl_registry_bind(
        registry, name, &zwp_virtual_keyboard_manager_v1_interface, 1);
  } else if (strcmp(interface, wl_seat_interface.name) == 0 && seat == NULL) {
    seat = wl_registry_bind(registry, name, &wl_seat_interface, 1);
  }
}

static void registry_global_remove(void *data, struct wl_registry *registry,
                                   uint32_t name) {
  (void)data;
  (void)registry;
  (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static uint32_t now_ms(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint32_t)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
}

/* Lowest keycode producing `sym` at shift level 0 of layout 0. */
static xkb_keycode_t find_keycode(struct xkb_keymap *keymap, xkb_keysym_t sym) {
  xkb_keycode_t min = xkb_keymap_min_keycode(keymap);
  xkb_keycode_t max = xkb_keymap_max_keycode(keymap);
  for (xkb_keycode_t kc = min; kc <= max; kc++) {
    const xkb_keysym_t *syms;
    int n = xkb_keymap_key_get_syms_by_level(keymap, kc, 0, 0, &syms);
    for (int i = 0; i < n; i++) {
      if (syms[i] == sym) return kc;
    }
  }
  return XKB_KEYCODE_INVALID;
}

int main(int argc, char **argv) {
  int gap_ms = 100;
  int argi = 1;
  if (argi < argc && strcmp(argv[argi], "-g") == 0) {
    gap_ms = atoi(argv[argi + 1]);
    argi += 2;
  }

  struct wl_display *display = wl_display_connect(NULL);
  if (!display) {
    fprintf(stderr, "wlkey: cannot connect to Wayland display\n");
    return 1;
  }
  struct wl_registry *registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &registry_listener, NULL);
  wl_display_roundtrip(display);
  if (!vk_manager || !seat) {
    fprintf(stderr, "wlkey: compositor lacks virtual-keyboard-v1 or seat\n");
    return 1;
  }

  struct zwp_virtual_keyboard_v1 *vk =
      zwp_virtual_keyboard_manager_v1_create_virtual_keyboard(vk_manager,
                                                              seat);

  struct xkb_context *ctx = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
  struct xkb_rule_names names = {.rules = "evdev", .layout = "kr"};
  struct xkb_keymap *keymap =
      xkb_keymap_new_from_names(ctx, &names, XKB_KEYMAP_COMPILE_NO_FLAGS);
  if (!keymap) {
    fprintf(stderr, "wlkey: cannot compile kr keymap\n");
    return 1;
  }
  char *keymap_string =
      xkb_keymap_get_as_string(keymap, XKB_KEYMAP_FORMAT_TEXT_V1);
  size_t keymap_size = strlen(keymap_string) + 1;
  int fd = memfd_create("wlkey-keymap", 0);
  if (fd < 0 || write(fd, keymap_string, keymap_size) < 0) {
    fprintf(stderr, "wlkey: cannot write keymap fd\n");
    return 1;
  }
  zwp_virtual_keyboard_v1_keymap(vk, WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1, fd,
                                 (uint32_t)keymap_size);
  wl_display_roundtrip(display);
  /* Give the compositor and the focused client a moment to install the
   * keymap before the first key event. */
  usleep(200 * 1000);

  xkb_mod_index_t shift_idx =
      xkb_keymap_mod_get_index(keymap, XKB_MOD_NAME_SHIFT);
  uint32_t shift_mask = (uint32_t)1 << shift_idx;

  for (int i = argi; i < argc; i++) {
    const char *token = argv[i];
    int shifted = 0;
    if (strncmp(token, "shift+", 6) == 0) {
      shifted = 1;
      token += 6;
    }
    xkb_keysym_t sym =
        xkb_keysym_from_name(token, XKB_KEYSYM_NO_FLAGS);
    if (sym == XKB_KEY_NoSymbol) {
      fprintf(stderr, "wlkey: unknown keysym '%s'\n", token);
      return 1;
    }
    xkb_keycode_t kc = find_keycode(keymap, sym);
    if (kc == XKB_KEYCODE_INVALID) {
      fprintf(stderr, "wlkey: keysym '%s' not in kr layout\n", token);
      return 1;
    }
    uint32_t evdev = (uint32_t)kc - 8;

    if (shifted) {
      zwp_virtual_keyboard_v1_modifiers(vk, shift_mask, 0, 0, 0);
      wl_display_flush(display);
      usleep(30 * 1000);
    }
    zwp_virtual_keyboard_v1_key(vk, now_ms(), evdev,
                                WL_KEYBOARD_KEY_STATE_PRESSED);
    wl_display_flush(display);
    usleep(40 * 1000);
    zwp_virtual_keyboard_v1_key(vk, now_ms(), evdev,
                                WL_KEYBOARD_KEY_STATE_RELEASED);
    wl_display_flush(display);
    if (shifted) {
      usleep(30 * 1000);
      zwp_virtual_keyboard_v1_modifiers(vk, 0, 0, 0, 0);
      wl_display_flush(display);
    }
    usleep((useconds_t)gap_ms * 1000);
  }

  wl_display_roundtrip(display);
  zwp_virtual_keyboard_v1_destroy(vk);
  wl_display_disconnect(display);
  free(keymap_string);
  return 0;
}
