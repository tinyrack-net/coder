# Testing and verification

Tinest uses layered tests so most behavior is verified without launching
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
  conversation, and provider settings states through `TinestApi` overrides.
- Linux canonical golden tests cover light/dark and desktop/mobile presentation.
- Debug E2E is split into daemon/workspace, project/worktree, cross-domain
  session/turn/Agent/skill/MCP, provider, and settings/desktop runner shards.
  The shards use embedded or local remote daemons with deterministic provider
  ports, check files and daemon readback, and reconnect or restart where the
  scenario requires persistence evidence.

## Feature traceability

`lib/src/feature_manifest.dart` owns the stable feature catalog. Every public
`TinestApi` method and every `@TypedGoRoute` must belong to exactly one feature.
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
dart run melos test:e2e:desktop
dart run melos verify:fast
dart run melos verify
dart run melos verify:debug
```

Use the same Flutter SDK version as the `FLUTTER_VERSION` value in
`.github/workflows/pipeline.yml` before running verification. The current pinned
version is 3.44.8; check the active SDK with `flutter --version`. The repository
does not install or switch Flutter SDKs automatically.

Windows verification requires Visual Studio with the **C++ CMake tools for
Windows** component. The verification and desktop E2E entrypoints discover the
bundled CMake and Ninja tools through Visual Studio Installer, so they do not
need to be added to the machine-wide `PATH`. If the component is missing, the
entrypoint stops with an installation-oriented error before starting the suite.

`verify:fast` checks formatting, strict analysis, dependency declarations,
architecture and feature contracts, generated-code drift, and
all Dart and Flutter tests. Generated-code drift is checked first; once it is
clean, independent checks run concurrently with a maximum of four tasks.
`verify` uses the coverage runs as the canonical test execution instead of
running the same tests once normally and again with instrumentation. Dart and
Flutter coverage run concurrently, followed by the per-package coverage
threshold check. Linux also runs the canonical goldens in a separate phase;
Windows and macOS omit that Linux-owned pixel gate. `verify:debug` is deliberately
separate because it compiles and launches the current host's desktop runner. The
`test:e2e:desktop` entrypoint selects `linux`, `macos`, or `windows`; Linux runs
each shard through `xvfb-run -a`, while Windows test windows can be visible. Each
E2E shard runs in a fresh Flutter process because a stopped desktop runner cannot
safely hand its debug log connection to the next integration file.

Focused layer commands remain available for development. `test:dart` is the
single-pass aggregate for the root and every non-Flutter package, including the
daemon vertical slice exactly once; `test:flutter` is the single-pass aggregate
for app unit and widget tests. Package processes use bounded concurrency so a
parallel workspace run does not multiply each package's own test workers.

## Machine-global resources

Tests never bind a fixed port. The app-owned daemon binds whatever
`AppSettings.embeddedDaemonPort` says and that value overrides the port in the
injected `DaemonConfig`, so a test that leaves the setting at its default binds
the product port for the whole machine. Every E2E file that starts the real
`IsolateEmbeddedDaemonLauncher` therefore takes its port from
`reserveEphemeralPort()` in `integration_test/support/ephemeral_port.dart` and
pins it on every `MemoryAppStore` it builds, and passes `resolveConfig` with a
temporary home so no run reaches the real daemon home or its exclusive
`daemon.lock`. `embedded-ports:check` enforces all three and runs as part of
`verify:fast` and `verify`.

The Linux runner is a unique `GApplication`, and Windows uses a named mutex, so
a normal second launch can be redirected to or rejected by the running app.
Desktop E2E therefore sets `TINYRACK_TINEST_ALLOW_MULTIPLE_INSTANCES=1`, which
keeps the test process to itself. It is safe precisely because the run already
owns an isolated daemon home.

`test:e2e:desktop` points `TINYRACK_TINEST_HOME` at a per-run temporary directory
on every supported host. Together these let two checkouts verify at the same
time and let `verify:debug` pass while a developer's own `melos run:daemon` holds
the product port. On Linux the entrypoint also gives each run its own display via
`xvfb-run -a`; invoke the Melos entrypoint instead of running the Flutter
integration tests directly.

Golden tests run in their own canonical Linux process. Coverage excludes the
`golden` tag so font/rendering configuration from unrelated test isolates cannot
make pixel comparisons nondeterministic; the same UI behavior remains covered by
widget tests. `test:golden` and the native IBus terminal E2E remain required
Linux CI gates, but their absence from a Windows or macOS local run is not a
local verification failure.

## Continuous integration

Merging goes through a merge queue. A pull request is not merged on the commit
it was tested at: the queue rebuilds it on top of whatever `main` has become,
runs the quality set against that projected merge, and squashes it in. Nothing
has to be rebased by hand to stay current, and a green pull request no longer
goes stale because another one landed first. Enable auto-merge and the queue
takes it from there.

Because the queue, not the pull request, is what `main` is actually reachable
through, the two run different scopes. Every pull request runs the Linux
static, generated-source, coverage, golden, Debug E2E, IBus terminal, web,
Android, and Linux CLI jobs. The merge queue adds what only a second host can
prove: the macOS and Windows Dart and Flutter test jobs, the macOS and Windows
Debug builds, the iOS build, and the remaining three CLI targets.

That split exists because every job restores a 1.7-2.1 GB Flutter SDK cache
that cannot be pruned. Measured against the published archives the cached blob
is the pristine SDK — Windows caches 1.81 GB against a 1.8 GB archive, macOS
2.08 against 2.1, Linux 1.69 against 1.5 — so there is no precache bloat to
strip, and the per-job cost is fixed. The pipeline pays it fewer times instead,
by moving the cross-platform jobs to the queue. Measured across four runs
before and one after, a pull request went from ~260 billed minutes to 33, and
from ~7.5 minutes of wall clock to 6.4 — this is overwhelmingly a cost saving,
not a latency one, because the jobs that moved ran in parallel and were rarely
the critical path.

Merging the Dart and Flutter suites into one job per host, to pay the setup
once, was tried and reverted. On Windows the suites take 7.6 and 4.4 minutes,
so a single job serialises them into 15.6 and the queue run went from 7.7 to
18.2 minutes. Repeating a sub-two-minute setup is the cheaper of the two, and
the queue gates every merge, so its wall clock is what matters.

Because the payload is identical either way, throughput is the only variable
left, and Windows restores that blob at ~6 MB/s against 48 MB/s for the same
blob on macOS. `setup-flutter` therefore skips the SDK cache on Windows alone
and fetches the archive from Google's CDN. That is the one tuning decision here
taken on inference rather than measurement: if a Windows setup step is not
faster than the 4.5 minutes it used to take, drop the condition in
`.github/actions/setup-flutter/action.yml` and cache unconditionally again.

Coverage is unaffected by any of this. It is collected only by
`coverage-dart-linux` and `coverage-flutter-linux`, both of which run on every
pull request, and the 90%/80% gate reads their LCOV exactly as before. What
moved to the queue were the macOS and Windows re-runs of those same suites,
which never produced coverage.

A `changes` job decides the scope. It narrows the CLI and mobile matrices from
`.github/ci-matrices.json`, and skips the whole matrix for a pull request whose
diff is only `docs/` and Markdown. An unreadable or empty file listing counts
as code, never as documentation.

Pull requests are additionally divided into conservative package scopes. A diff
entirely under `packages/relay/` runs static checks, relay branch coverage, and
the relay image smoke test without starting the Flutter application matrix. A
diff entirely under `packages/app/` runs the application coverage, generated,
golden, Debug E2E, IBus, mobile, and web gates without re-running unchanged Dart
package coverage or the CLI build. Mixed changes, shared `relay_protocol`
changes, and repository-level changes run the full matrix. Merge queue, main,
tag, and manual runs are always full, so the projected merge commit still
receives every gate.

Three consequences worth knowing. A queue run reports as the `merge_group`
event rather than `pull_request`, so a job that must run before merging cannot
be gated on `pull_request` alone. A cancelled queue check counts as a failure
that ejects the pull request, which is why merge-queue runs opt out of
`cancel-in-progress`. And `Quality Gate`, the sole required branch-protection
check, accepts a `skipped` job — that is how a scoped-out job passes — but
fails if `changes` itself failed, since that would skip everything at once.

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

The full Dart coverage job enforces `agent`, `cli`, `client`, `daemon`,
`protocol`, `relay`, and `relay_protocol`; the Flutter coverage job enforces
`app`. A relay-only pull request collects and enforces `relay` coverage in its
focused lane, while a `relay_protocol` change uses the full Dart lane because
that protocol is shared by the application, client, and daemon.

## Completion report

Every final implementation report must include:

- tests added or changed;
- exact verification commands run;
- line and branch coverage for every package;
- the Debug target that ran;
- platforms or checks not run locally and the CI job that owns them.
