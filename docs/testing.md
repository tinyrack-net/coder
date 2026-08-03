# Testing and verification

Tinyrack Coder uses layered tests so most behavior is verified without launching
the desktop application, followed by a real Debug runner gate for the complete
embedded-daemon path.

## Test layers

- Unit tests cover the agent lifecycle, permission policies, tool safety,
  repositories, provider catalog logic, and application notifiers using manual
  fakes and in-memory adapters.
- Contract tests cover typed JSON-RPC DTOs, malformed payloads, protocol versions,
  reconnect and timeline semantics, and recorded Responses/Chat Completions SSE.
- Vertical-slice tests use real daemon services and WebSockets with temporary
  homes, deterministic provider/OAuth ports, and local Git repositories. They
  cover every command that changes user state without launching Flutter.
- Widget tests cover loading, data, empty, error, responsive, navigation, approval,
  conversation, and provider-administration states through `CoderApi` overrides.
- Linux canonical golden tests cover light/dark and desktop/mobile presentation.
- Debug E2E starts an embedded daemon with a deterministic fake model provider,
  drives the real Linux Flutter runner through remote workspace registration,
  worktree lifecycle, Markdown Agent create/edit/reload/archive/reset, session
  delegation, approval, and provider connection/disconnection. It checks files
  and daemon readback, then reconnects to verify persisted timeline recovery.

## Feature traceability

`lib/src/feature_manifest.dart` owns the stable feature catalog. Every public
`CoderApi` method and every `@TypedGoRoute` must belong to exactly one feature.
Each feature declares the layers required to prove it.

Tests expose evidence with executable tags using this encoding:

```dart
tags: const <String>['feature_test__agent_definition_management__widget']
```

Dots in the manifest ID become underscores in the test tag. Add the tag to a
test that actually exercises the stated behavior; a marker without behavior is
not acceptable evidence. `features:check` fails for unknown tags, skipped tagged
files, missing layers, unregistered API methods/routes, and duplicate ownership.

## Commands

```sh
dart pub get --enforce-lockfile
dart run melos test:unit
dart run melos test:widget
dart run melos test:contract
dart run melos test:vertical-slice
dart run melos test:golden
dart run melos test:coverage
dart run melos verify:fast
dart run melos verify
xvfb-run -a dart run melos verify:debug
```

`verify:fast` checks formatting, strict analysis, dependency declarations,
architecture and feature contracts, generated-code drift, and
unit/widget/contract/vertical-slice tests. `verify` adds goldens and per-package
coverage. `verify:debug` is deliberately separate because it compiles and
launches the Linux desktop runner.

Golden tests run in their own canonical Linux process. Coverage excludes the
`golden` tag so font/rendering configuration from unrelated test isolates cannot
make pixel comparisons nondeterministic; the same UI behavior remains covered by
widget tests and `test:golden` is still a required gate.

## Coverage

`tool/verify_coverage.dart` enforces 90% line and 80% branch coverage separately
for every app/package. Production Dart files missing from LCOV count as uncovered.
Only `.g.dart` and `.freezed.dart` files are excluded. Do not use coverage-ignore
comments to change the denominator.

## Completion report

Every final implementation report must include:

- tests added or changed;
- exact verification commands run;
- line and branch coverage for every package;
- the Debug target that ran;
- platforms or checks not run locally and the CI job that owns them.
