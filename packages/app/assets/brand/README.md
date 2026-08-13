# Tinest brand assets

Every icon in this repository is derived from one upstream master. Do not
retouch a generated file; change the master and regenerate.

## Master

`@tinyrack/ui/brand/apps/tinest-app-icon.svg`, maintained in the
[design repository](https://github.com/tinyrack-net/design) under
`packages/ui_web/src/brand/apps/`. It is a 64×64 vector on the shared Tinyrack
app icon grid: a `#0a0a0a` tile, three `#fafafa` output rows, and one `#a78bfa`
prompt chevron. The design repository enforces that grid and palette in tests,
so a new accent color or a moved row belongs there, not here.

`tinest.svg` in this directory is a verbatim copy of that master.
`tinest-128.png`, `tinest-256.png`, `tinest-512.png`, and `tinest-1024.png` are
rasterized from it. They remain the source for in-app artwork, the boot splash,
web icons, and Linux packaging.

## Native launcher icons

The design repository derives two launcher-specific assets from the master:

| File | Use |
| --- | --- |
| `tinest-launcher-icon-1024.png` | Android legacy and iOS icons. It includes the upstream 12.5% launcher-safe inset. |
| `tinest-adaptive-foreground-1024.png` | Tileless Android adaptive foreground, centered in the platform safe zone. |

`pubspec.yaml` selects these files with `image_path_android`,
`image_path_ios`, and `adaptive_icon_foreground`. Use a mobile-only temporary
configuration when regenerating Android and iOS so the independently managed
web icons remain unchanged:

```sh
cd packages/app
dart run flutter_launcher_icons -f <mobile-only-config>
```

The temporary configuration must copy only the Android, iOS, adaptive
background, adaptive foreground, and iOS alpha-removal values from
`pubspec.yaml`.

## Icons the launcher generator does not produce correctly

Web maskable and tray icons need different composition and are not covered by
the mobile launcher inputs.

| File | Why it differs |
| --- | --- |
| `../../web/icons/Icon-maskable-192.png`, `-512.png` | A maskable icon is cropped to a circle 80% of its width, so the tile becomes a full-bleed `#0a0a0a` field. The glyph's farthest corner stays inside that circle. |
| `../tray/tray_icon*.png`, `tray_icon.ico` | The tray renders the glyph alone in one color. The `_template` variants carry their shape in alpha only and are drawn solid black, because macOS recolors template images to match the menu bar. |

Rasterizing these requires an SVG renderer, which this repository does not
depend on. Regenerate them alongside the master in the design repository, which
already has one, and copy the results in.
