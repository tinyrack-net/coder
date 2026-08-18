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
5. Give each test its own state: a fresh temporary directory, an
   ephemeral or injected port, its own container or provider instance, and no
   mutable top-level variable shared across tests. Await the condition you care
   about rather than a duration.

Use focused commands while iterating:

```sh
cd packages/<dart-package> && dart test [path-or-tag]
cd packages/app && flutter test [path-or-tag]
```

`dart run melos test` is available when a broader single-pass workspace check
is useful, but it is not required before opening a Draft pull request. Do not
chain unit, contract, and vertical-slice commands as an aggregate; that reruns
the same package tests.

The quality runner uses `Platform.numberOfProcessors` by default. Set
`TINEST_JOBS` for Melos commands, or call `dart run tinest_quality <command>
--jobs=N` when reproducing a resource-sensitive failure. Add
`--report=build/quality/<name>.json` for machine-readable task durations and
resource-slot utilization. Do not hard-code a package fan-out or test
concurrency in Melos or CI. `--jobs` is a diagnostic for reproducing a failure,
not a remedy: a suite that only passes at a lower job count is still broken, and
leaving it lowered slows every later run.

## Apply change-specific gates

- Run widget tests for UI behavior changes. Assert the layout, spacing, and
  colour values that changed; there is no pixel gate to fall back on.
- Run contract and real-daemon vertical-slice tests for protocol or daemon
  changes.
- Provide contract, real-daemon vertical-slice, and widget evidence for
  user-state mutations.
- Provide Linux E2E evidence for primary-screen happy paths through PR CI or a
  focused local scenario.
- Require the affected platform Debug build for platform-specific changes, but
  let PR or merge-group CI own it unless it is the smallest useful local
  reproduction.

## Hand full verification to PR CI

After the directly affected tests pass, run any input-specific checks:

```sh
dart run tinyrack_workspace source-check # dependency changes
dart test packages/tinest_quality/test/pipeline_test.dart # workflow changes
git diff --check
```

Run code generation and commit its output whenever generation inputs changed.
Then open a Draft pull request. The `Quality Gate` for the pull request's exact
head commit is the authoritative full verification; mark the pull request ready
only after it passes. If merging is in scope, require the matching merge-group
`Quality Gate` before reporting completion.

PR CI owns static checks, generated-source drift, package coverage thresholds,
Linux Debug E2E, native IBus terminal E2E, Android, Web, and the host CLI build.
The merge queue adds the cross-platform test and build evidence that gates
`main`. Do not report full verification while either applicable gate is running
or failing.

When CI fails, start with the failing job's smallest relevant local command.
Run a focused desktop scenario through the supported runner rather than the
entire catalog when one scenario is implicated:

```sh
dart run packages/desktop_app/tool/run_desktop_e2e.dart --scenario=<id> --jobs=N
```

Use the full local gates only when the user explicitly requests them, PR CI is
unavailable, or a CI failure cannot be isolated with a focused command:

```sh
dart run melos verify
dart run melos verify:debug
```

`verify` runs generated-source drift, static checks, coverage, and coverage
threshold enforcement. Coverage is the canonical execution of package and app
tests, so do not run an additional aggregate suite merely to duplicate it.

Never emulate a host. Do not use Docker, Podman, a container, WSL, a virtual
machine, or a remote Linux machine to run a gate the local host cannot run. The
only such gate is the native IBus terminal E2E, which needs a live `ibus-daemon`
and an X11 session; report it as owned by `linux-ibus-terminal-e2e` rather than
reproducing it.

`verify:debug` delegates to the desktop-app-owned E2E runner. With one job it
runs the catalog serially; with two or more jobs it balances the catalog over
at most two isolated lanes. Each lane has its own persistent Flutter build
directory and temporary app/config home. The second build starts only after
the first native app signals readiness, so the tests overlap without racing
Flutter's desktop build cache. Use `dart run tinest_quality e2e --jobs=N
--report=build/quality/e2e.json` to measure or reproduce the full runner.
Linux uses `xvfb-run -a`; Windows can show two app windows. Do not bypass the
entrypoint with direct `flutter test` commands.

After changing `.github/workflows/`, run the focused
`packages/tinest_quality/test/pipeline_test.dart` locally. Let the PR's Static
checks job own `actionlint` and confirm its result before reporting full
verification.

## Fix an intermittent failure instead of passing it by

A test that fails once and passes on the next run is an open defect, whether it
surfaced locally or in a PR or merge-group job. Never re-run, re-queue, or
force-push to get a green result, and never report the change as verified while
one of its runs failed.

Reproduce it deliberately:

```sh
dart test --test-randomize-ordering-seed=<seed>   # the seed printed by the failing run
dart test <file> --name '<test>' --total-shards=1 # confirm it passes alone
dart test                                          # then the whole package, where leakage shows
```

A test that passes alone and fails in the package run is telling you the cause
is shared state, not the assertion. Look for a leaked singleton or top-level
variable, work started but not awaited, a real `Timer`, `Future.delayed`, or
`DateTime.now`, a fixed port or fixed temporary path, an undisposed provider
container or subscription, and an `addTearDown` that never ran.

Fix the mechanism and keep the suite parallel-safe:

- isolate the resource — unique temporary directory, ephemeral port, per-test
  container, injected fake clock, ID generator, filesystem, or process;
- await the real condition — a completer, stream event, or
  `pumpAndSettle` — rather than sleeping for a duration that happens to work;
- tear down everything the test created, in `addTearDown`, so ordering cannot
  matter.

Do not stabilize a test by serializing it, tagging it exclusive, lowering
`--jobs` or `TINEST_JOBS`, inserting a sleep, adding a retry wrapper, or
skipping it. Those hide the defect and make every future run slower. If the
fix genuinely requires an exclusive resource, isolate that resource behind a
port instead of the suite around it.

State the mechanism you found and the fix when you report the run. If a failure
resists reproduction, say so explicitly with the seed, the command, and what you
ruled out; do not report it as passing.

## Report evidence

Include:

- tests added or changed;
- exact commands run and their result;
- line and branch coverage from the authoritative PR CI jobs;
- the locally run Debug target or the PR CI job that supplied that evidence;
- checks omitted locally and owned by PR or merge-group CI;
- any run that failed and later passed, with the seed, the mechanism found, and
  the fix;
- the native IBus terminal E2E as evidence owned by `linux-ibus-terminal-e2e`,
  which no host runs locally.

Do not report full verification when analysis has diagnostics, generated
sources drift, feature evidence is missing, any package is below 90% line or
80% branch coverage, required CI evidence did not execute, the exact-head
`Quality Gate` has not passed, or any run of the change failed intermittently
and is still unexplained.
