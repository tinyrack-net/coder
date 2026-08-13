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
rasterized from it and are what `shipworld.yaml` ships as the Linux desktop
icon.

The shared brand directory also mirrors `tinest-launcher-icon-1024.png` and
`tinest-adaptive-foreground-1024.png` from upstream. They are the mobile-safe
launcher sources; keeping the copies here preserves the mobile/desktop brand
asset synchronization contract. Desktop launcher generation remains unchanged.

## Native launcher icons

`tinest-1024.png` is the source for the macOS and Windows launcher icons.
Regenerate them after replacing the master:

```sh
cd packages/desktop_app
dart run flutter_launcher_icons
```

The configuration lives in `pubspec.yaml` under `flutter_launcher_icons`.

## Icons the launcher generator does not produce correctly

Three families need the glyph placed differently and are not covered by
`flutter_launcher_icons`. Each drops the rounded tile and repositions the glyph
alone, scaled to 79.4% of a square canvas so that it keeps the 54% visual weight
it has inside the tile.

| File | Why it differs |
| --- | --- |
| `../tray/tray_icon*.png`, `tray_icon.ico` | The tray renders the glyph alone in one color. The `_template` variants carry their shape in alpha only and are drawn solid black, because macOS recolors template images to match the menu bar. |

Rasterizing these requires an SVG renderer, which this repository does not
depend on. Regenerate them alongside the master in the design repository, which
already has one, and copy the results in.
