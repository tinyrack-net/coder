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
- Widget tests cover loading, data, empty, error, responsive, navigation, approval,
  conversation, and provider-administration states through `CoderApi` overrides.
- Linux canonical golden tests cover light/dark and desktop/mobile presentation.
- Debug E2E starts an embedded daemon with a deterministic fake model provider,
  drives the real Linux Flutter runner through agent creation and approval, checks
  the resulting file, and reconnects to verify persisted timeline recovery.

## Commands

```sh
dart pub get --enforce-lockfile
dart run melos test:unit
dart run melos test:widget
dart run melos test:contract
dart run melos test:golden
dart run melos test:coverage
dart run melos verify:fast
dart run melos verify
xvfb-run -a dart run melos verify:debug
```

`verify:fast` checks formatting, strict analysis, dependency declarations,
architecture rules, generated-code drift, and unit/widget/contract tests. `verify`
adds goldens and per-package coverage. `verify:debug` is deliberately separate
because it compiles and launches the Linux desktop runner.

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
