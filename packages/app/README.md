# app

Cross-platform Flutter client for Tinest. The app uses a feature-first
layout with Riverpod application controllers and typed `go_router` navigation.

## Source layout

```text
lib/src/
  app/                       application composition, routes, and cross-feature shells
  features/<feature>/
    application/             Riverpod state and user commands
    domain/                  pure app-owned rules and value types, when needed
    infrastructure/          platform and persistence adapters, when needed
    presentation/            feature-owned pages and widgets
  shared/                    feature-neutral domain and presentation code
```

For developers coming from React, `app/router` is the route table,
`presentation/pages` contains route-level components,
`presentation/widgets` contains feature components, and `application` contains
the feature's typed store and actions. Riverpod also supplies dependency
injection at the composition root.

Cross-feature page and widget composition belongs in `app/presentation`.
Feature-neutral components belong in `shared`; shared code cannot import a
feature. Domain code does not import Flutter or platform packages, and
application controllers do not instantiate transports, filesystems, clocks, or
ID generators.

`TinestApi` and `protocol` DTOs are already transport-neutral boundaries.
Do not wrap them mechanically in repositories or duplicate DTO models. Add a
repository or use-case only when the app owns a source of truth, caching,
retry/merge behavior, or reusable multi-source business logic.

Tests mirror the same ownership under `test/app`, `test/features`, and
`test/shared`. Cross-feature app flows have a small driver in `test/app` with
feature-owned test cases beside the relevant feature tests.

## Settings visual catalog

Run the deterministic Settings screen catalog from `packages/app`:

```console
flutter test tool/settings_screen_catalog_test.dart
```

The catalog accepts these environment variables:

- `SETTINGS_CATALOG_PHASE` names the output phase and defaults to `current`.
- `SETTINGS_CATALOG_SCOPE` selects `all`, `base`, or `state` captures.
- `SETTINGS_CATALOG_SCENARIOS`, `SETTINGS_CATALOG_VIEWPORTS`, and
  `SETTINGS_CATALOG_VARIANTS` filter comma-separated IDs. Their singular
  `SCENARIO`, `VIEWPORT`, and `VARIANT` aliases accept one ID.
- `SETTINGS_CATALOG_BASELINE_PHASE` names an existing phase to compare and
  generates side-by-side contact sheets.

Each run replaces `build/settings-screen-catalog/<phase>` with PNG captures and
a `manifest.json` recording the fixture, viewport, theme, locale, text scale,
interaction, scroll checkpoint, and contact-sheet metadata. With a baseline,
comparisons are written below that phase's `contact-sheets` directory.

These images are manual visual-audit artifacts, not committed goldens or a CI
pixel gate. Stable regressions belong in widget tests that assert layout,
spacing, colour, semantics, and interaction values directly.
