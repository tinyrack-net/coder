---
name: verify-coder-workspace
description: Select, run, and report the correct test, coverage, generated-code, platform, CI, and release gates for the Tinyrack Coder Dart/Flutter workspace. Use when changing behavior, adding tests, diagnosing a failed gate, preparing a PR or release, checking completion, updating CI, or deciding which Melos verification command and platform evidence a Coder change requires.
---

# Verify Coder Workspace

Read `AGENTS.md` and `docs/testing.md` before changing code. Treat them as the
source of truth when this skill and the repository diverge.

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
dart run melos test:golden
dart run melos test:coverage
```

Prefer `test:dart` and `test:flutter` for a single-pass workspace check. Do not
chain unit, contract, and vertical-slice commands as an aggregate; that reruns
the same package tests.

## Apply change-specific gates

- Run widget tests for UI behavior changes. If pixels change, update and verify
  the canonical Linux golden.
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
xvfb-run -a dart run melos verify:debug
```

`verify` runs generated-source drift first, then static checks, coverage, and
goldens concurrently. Coverage is the canonical execution of package and app
tests, so do not run an additional aggregate suite merely to duplicate it.

If `xvfb-run` is unavailable but a Linux display exists, run
`dart run melos verify:debug` directly. Otherwise report Linux Debug E2E as
unverified and name the `Linux Debug E2E` CI job.

Run `actionlint` after changing `.github/workflows/`. Confirm PR/main, tag,
manual, and schedule conditions with `test/pipeline_test.dart`.

## Report evidence

Include:

- tests added or changed;
- exact commands run and their result;
- line and branch coverage for every package;
- the Debug target that ran;
- platforms or checks not run locally and the CI jobs responsible for them.

Do not report success when analysis has diagnostics, generated sources drift,
feature evidence is missing, any package is below 90% line or 80% branch
coverage, or the required Debug runner did not execute.
