# Tinyrack Coder engineering policy

This repository is under active development. Prefer a sound, type-safe Dart and
Flutter design over compatibility with development data, deprecated APIs, or an
older internal protocol. Do not add compatibility shims or legacy adapters unless
the user explicitly requests them.

## Tinyrack dependency sources

Consume packages owned by `tinyrack-net`, including `tinyrack_ui`, `cliweave`,
`dartage`, `shipworld`, and `dropwell`, from their public Git repositories at
exact 40-character commit SHAs. Do not use pub.dev, moving branches or tags, path
dependencies, or `dependency_overrides` for these packages. Run
`dart run melos tinyrack-sources:check` after changing dependencies.

Before upgrading anything, read [`docs/dependencies.md`](docs/dependencies.md).
It records which packages `flutter pub outdated` reports as upgradable but are
in fact pinned shut by the Flutter SDK or an upstream package, and why.

## UI design system

For every Flutter UI implementation, modification, refactor, review, styling,
layout, component-selection, theme, or pixel-changing test task, use
`$tinyrack-coder-design-guidelines` and follow
`.agents/skills/tinyrack-coder-design-guidelines/SKILL.md`.

All controls and surfaces must use the public `tinyrack_ui` component when one
exists. Every visual design value, including color, spacing, dimensions,
typography, radius, elevation, opacity, icon size, and motion, must come from a
public Tinyrack token. Product-specific composites may remain in this repository
only when they are composed entirely from public TR components and tokens.

When a reusable primitive, interaction contract, component variant, or token is
missing, stop the consumer implementation and use the skill's authorized
upstream workflow to add it in `~/Workspaces/tinyrack/design`, merge it, pin the
consumer to the exact 40-character merge commit from the public Git repository,
and then resume the original work. Do not substitute a private clone, hardcoded
design value, pub-cache edit, path dependency, moving Git ref, or
`dependency_overrides`.

## Required workflow

1. Write a test that fails for the intended reason before changing production
   behavior. For refactors, add a characterization test first when the behavior is
   not already fixed by tests.
2. Keep business logic behind typed ports. Production application code must not
   instantiate concrete transports, databases, filesystems, processes, clocks, or
   ID generators outside a composition root.
3. Never edit generated `.g.dart` or `.freezed.dart` files by hand. Run the
   generator and commit its output.
4. Add unit and contract tests for every behavior change. UI changes also require
   widget tests and an updated Linux golden when pixels change. Protocol or daemon
   changes require contract and daemon integration tests.
5. Register every new or changed capability in the typed feature manifest and
   add executable `feature_test__<feature_id>__<layer>` tags for every required
   layer. User-state mutations require contract, real-daemon vertical-slice, and
   widget evidence; primary screen happy paths require Linux E2E evidence. Every
   typed route also requires executable `route_test__<route>__widget` evidence at
   desktop and mobile sizes.
6. Before reporting completion, run `dart run melos verify` and
   `dart run melos verify:debug`. The latter must exercise the real Debug Flutter
   runner and embedded daemon, not only a mocked widget tree.
7. Run a platform Debug build for every platform-specific change. If the current
   machine cannot run that platform, explicitly report it as unverified and name
   the CI job responsible for it.

## Non-negotiable gates

- `dart analyze --fatal-infos` has zero diagnostics under strict casts,
  inference, raw types, and `very_good_analysis`.
- Dependency and architecture verification have zero violations.
- Feature verification has no unregistered `CoderApi` method, typed route,
  unknown/skip tag, or missing required test layer.
- Each package independently has at least 90% line and 80% branch coverage.
  Missing production files count as 0%; only generated sources are excluded.
- Tests use deterministic clocks, IDs, memory filesystems, fake processes,
  recorded provider streams, and fake WebSockets. CI must never use a real API
  key, paid provider request, user home, or internet-dependent provider call.
- Test order is randomized. Preserve the printed seed whenever reproducing a
  failure.

Do not use broad lint ignores, coverage ignores, skipped tests, or broad exception
catches to make a gate pass. A necessary line-level ignore must include a comment
explaining the reason and safety argument.

The commands, test taxonomy, coverage rules, and platform matrix are documented in
[`docs/testing.md`](docs/testing.md).
