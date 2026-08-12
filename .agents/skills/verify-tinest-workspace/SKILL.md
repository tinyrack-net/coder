---
name: verify-tinest-workspace
description: Select, run, and report the correct test, coverage, generated-code, platform, CI, and release gates for the Tinest Dart/Flutter workspace. Use when changing behavior, adding tests, diagnosing a failed gate, preparing a PR or release, checking completion, updating CI, or deciding which Melos verification command and platform evidence a Tinest change requires.
---

# Verify Tinest Workspace

Read `AGENTS.md` before changing code. Treat it as the source of truth when
this skill and the repository diverge.

## Develop with the right evidence

1. Add a failing test before changing production behavior. For a refactor whose
   behavior is not fixed by tests, add a characterization test first.
2. Select every layer required by the typed feature manifest. Add executable
   `feature_test__<feature_id>__<layer>` tags and route tags where applicable.
3. Never edit `.g.dart` or `.freezed.dart` files. Run the generator.
4. Keep tests deterministic: use fake clocks, IDs, filesystems, processes,
   provider streams, and WebSockets. Preserve any random seed from a failure.

Use focused commands while iterating:

```sh
dart run melos test:dart
dart run melos test:flutter
dart run melos test:contract
dart run melos test:vertical-slice
dart run melos test:coverage
```

Prefer `test:dart` and `test:flutter` for a single-pass workspace check. Do not
chain unit, contract, and vertical-slice commands as an aggregate; that reruns
the same package tests.

## Apply change-specific gates

- Run widget tests for UI behavior changes. Assert the layout, spacing, and
  colour values that changed; there is no pixel gate to fall back on.
- Run contract and real-daemon vertical-slice tests for protocol or daemon
  changes.
- Provide contract, real-daemon vertical-slice, and widget evidence for
  user-state mutations.
- Provide Linux E2E evidence for primary-screen happy paths.
- Run the affected platform Debug build for platform-specific changes. If the
  platform is unavailable, name the CI job that owns the missing evidence.

## Complete the change

Run both required gates before reporting completion:

```sh
dart run melos verify
dart run melos verify:debug
```

`verify` runs generated-source drift first, then static checks and coverage,
then the coverage threshold check. Every one of its gates
runs natively on Linux, macOS, and Windows, so a passing run means the same
thing on every host. Coverage is the canonical execution of package and app
tests, so do not run an additional aggregate suite merely to duplicate it.

Never emulate a host. Do not use Docker, Podman, a container, WSL, a virtual
machine, or a remote Linux machine to run a gate the local host cannot run. The
only such gate is the native IBus terminal E2E, which needs a live `ibus-daemon`
and an X11 session; report it as owned by `linux-ibus-terminal-e2e` rather than
reproducing it.

`verify:debug` delegates to `test:e2e:desktop`, which selects the current Linux,
macOS, or Windows Flutter device and runs every shard with an isolated temporary
home. Linux uses `xvfb-run -a`; Windows can show application windows during the
run. Do not bypass the entrypoint with direct `flutter test` commands. If the
current platform cannot run Debug E2E, report it as unverified and name the CI
job that owns the missing evidence.

Run `actionlint` after changing `.github/workflows/`. Confirm PR/main, tag,
manual, and schedule conditions with `test/pipeline_test.dart`.

## Report evidence

Include:

- tests added or changed;
- exact commands run and their result;
- line and branch coverage for every package;
- the Debug target that ran;
- platforms or checks not run locally and the CI jobs responsible for them;
- the native IBus terminal E2E as evidence owned by `linux-ibus-terminal-e2e`,
  which no host runs locally.

Do not report success when analysis has diagnostics, generated sources drift,
feature evidence is missing, any package is below 90% line or 80% branch
coverage, or the required Debug runner did not execute.
