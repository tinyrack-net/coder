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
  conversation, and provider settings states through `CoderApi` overrides.
- Linux canonical golden tests cover light/dark and desktop/mobile presentation.
- Debug E2E is split into daemon/workspace, project/worktree, cross-domain
  session/turn/Agent/skill/MCP, provider, and settings/desktop runner shards.
  The shards use embedded or local remote daemons with deterministic provider
  ports, check files and daemon readback, and reconnect or restart where the
  scenario requires persistence evidence.

## Feature traceability

`lib/src/feature_manifest.dart` owns the stable feature catalog. Every public
`CoderApi` method and every `@TypedGoRoute` must belong to exactly one feature.
Each feature declares the layers required to prove it.

Every feature that requires E2E evidence also declares typed scenarios and the
desktop and/or mobile surfaces that support them. Scenario evidence uses this
encoding:

```dart
tags: const <String>[
  'feature_scenario__turn_execution__cancel_stream__e2e',
]
```

Scenario tests must use `testWidgets`, perform asynchronous runner behavior,
and assert an observable result. The verifier rejects undeclared, duplicate,
empty, skipped, marker-only, or missing scenarios. A scenario tag also supplies
the feature's E2E layer evidence; a broad feature tag alone cannot satisfy a
declared scenario.

Tests expose evidence with executable tags using this encoding:

```dart
tags: const <String>['feature_test__agent_definition_management__widget']
```

Dots in the manifest ID become underscores in the test tag. Add the tag to a
test that actually exercises the stated behavior; a marker without behavior is
not acceptable evidence. `features:check` fails for unknown tags, skipped tagged
files, missing layers, unregistered API methods/routes, and duplicate ownership.

Every typed route must also render at desktop and mobile sizes without Flutter
exceptions. Route tests use `route_test__<snake_case_route_class>__widget`, for
example `route_test__provider_settings_route__widget`. `features:check` fails
when a typed route has no matching executable route test or when the tag is
unknown or skipped.

## Commands

```sh
dart pub get --enforce-lockfile
dart run melos test:dart
dart run melos test:flutter
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
all Dart and Flutter tests. Generated-code drift is checked first; once it is
clean, independent checks run concurrently with a maximum of four tasks.
`verify` uses the coverage runs as the canonical test execution instead of
running the same tests once normally and again with instrumentation. Dart and
Flutter coverage plus goldens run concurrently, followed by the per-package
coverage threshold check. `verify:debug` is deliberately separate because it
compiles and launches the Linux desktop runner. Each E2E shard runs in a fresh
Flutter process because a stopped desktop runner cannot safely hand its debug
log connection to the next integration file.

Focused layer commands remain available for development. `test:dart` is the
single-pass aggregate for the root and every non-Flutter package, including the
daemon vertical slice exactly once; `test:flutter` is the single-pass aggregate
for app unit and widget tests. Package processes use bounded concurrency so a
parallel workspace run does not multiply each package's own test workers.

Golden tests run in their own canonical Linux process. Coverage excludes the
`golden` tag so font/rendering configuration from unrelated test isolates cannot
make pixel comparisons nondeterministic; the same UI behavior remains covered by
widget tests and `test:golden` is still a required gate.

## Continuous integration

Pull requests and main pushes run independent static, generated-source,
platform-test, coverage, golden, Debug E2E, and mobile-build jobs. Linux coverage
is the Linux execution of the full suite; macOS and Windows run the non-coverage
Dart and Flutter suites independently. The `Quality Gate` job requires every
job to succeed and is the sole required branch-protection check.

Nightly runs the same desktop shard matrix on macOS and Windows. Android and
iOS run the remote-only bootstrap and provider suites; desktop-owned daemon,
tray, window, and local Git-process scenarios remain desktop-only. Release
packages are built only for version tags or an explicit manual
dispatch. Tag builds start in parallel with verification, while publishing
waits for both `Quality Gate` and all four platform artifacts. Homebrew and
WinGet publishing proceed independently after the GitHub Release is available.

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
