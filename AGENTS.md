# Tinest engineering policy

This repository is under active development. Prefer a sound, type-safe Dart and
Flutter design over compatibility with development data, deprecated APIs, or an
older internal protocol. Do not add compatibility shims or legacy adapters unless
the user explicitly requests them.

## Tinyrack dependency sources

Consume packages owned by `tinyrack-net`, including `tinyrack_ui`, `cliweave`,
`dartage`, `shipworld`, and `dropwell`, from their public Git repositories at
exact 40-character commit SHAs. Do not use pub.dev, moving branches or tags, path
dependencies, or `dependency_overrides` for these packages. Run
`dart run tinyrack_workspace source-check` after changing dependencies.

`flutter pub outdated` reports packages as upgradable that are in fact pinned
shut by the Flutter SDK or an upstream package. Before upgrading anything,
resolve the constraint that actually holds the version down and say what it is;
a bump that only passes because the lockfile was regenerated is not an upgrade.

## UI design system

For every Flutter UI implementation, modification, refactor, review, styling,
layout, component-selection, theme, or pixel-changing test task, use
`$tinyrack-tinest-design-guidelines` and follow
`.agents/skills/tinyrack-tinest-design-guidelines/SKILL.md`.

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
   widget tests asserting the affected layout and styling values. Protocol or daemon
   changes require contract and daemon integration tests.
5. Register every new or changed capability in the typed feature manifest and
   add executable `feature_test__<feature_id>__<layer>` tags for every required
   layer. User-state mutations require contract, real-daemon vertical-slice, and
   widget evidence; primary screen happy paths require Linux E2E evidence. Every
   typed route also requires executable `route_test__<route>__widget` evidence at
   desktop and mobile sizes.
6. Keep the local loop focused. Before opening a pull request, prove the new or
   changed behavior with the directly affected tests, run code generation when
   its inputs changed, run `dart run tinyrack_workspace source-check` for
   dependency changes, and run `git diff --check`. Workflow changes also require
   a focused run of `packages/tinest_quality/test/pipeline_test.dart`.
7. After those focused checks pass, open a Draft pull request and use the PR's
   exact-head `Quality Gate` as the authoritative full verification. Mark it
   ready only after that gate passes. A task that includes merging is complete
   only after the matching merge-group `Quality Gate` passes.
8. When CI fails, reproduce the failing job with the smallest relevant local
   command before widening the run. Do not emulate another host with Docker,
   Podman, a container, WSL, a virtual machine, or a remote machine. Platform
   builds, full coverage, the Debug E2E catalog, and native IBus terminal E2E
   may be owned by their PR or merge-group CI jobs.
9. Treat an intermittent failure as a failure of the change in front of you.
   Reproduce it with the printed seed, find the mechanism, and fix it before
   continuing. Do not re-run, re-queue, force-push, or move on because a second
   attempt was green.

## Non-negotiable gates

- `dart analyze --fatal-infos` has zero diagnostics under strict casts,
  inference, raw types, and `very_good_analysis`.
- Dependency and architecture verification have zero violations.
- Feature verification has no unregistered `TinestApi` method, typed route,
  unknown/skip tag, or missing required test layer.
- Each package independently has at least 90% line and 80% branch coverage.
  Missing production files count as 0%; only generated sources are excluded.
- Tests use deterministic clocks, IDs, memory filesystems, fake processes,
  recorded provider streams, and fake WebSockets. CI must never use a real API
  key, paid provider request, user home, or internet-dependent provider call.
- Test order is randomized. Preserve the printed seed whenever reproducing a
  failure.
- A test that both passes and fails on the same commit is a defect that must be
  diagnosed and fixed. The cause is real: shared or leaked state between tests,
  unawaited work, a real timer or wall-clock read, a fixed port, a shared
  temporary path, or an order-dependent global. Name the mechanism in the fix.
- Tests must stay safely parallel. Fix flakiness by isolating what each test
  owns, awaiting the condition instead of a duration, and injecting a fake for
  the shared resource. Do not fix it by lowering concurrency, serializing a
  suite, hard-coding a job count, adding a sleep, or retrying the test.

Do not use broad lint ignores, coverage ignores, skipped tests, test retries or
reruns, or broad exception catches to make a gate pass. A necessary line-level
ignore must include a comment explaining the reason and safety argument.

`dart run melos verify` and `dart run melos verify:debug` remain available for
explicitly requested local verification, for work that cannot use PR CI, or
when a CI failure cannot be isolated with a focused command. They are not a
prerequisite for opening a Draft pull request. `verify` uses the coverage runs
as the canonical test execution rather than running the suites once plain and
again instrumented.

Do not report full verification while the exact-head PR `Quality Gate` is still
running or failing. Report locally omitted full gates as owned by PR CI, not as
locally passed. When merging, match the merge-group result to the pull request;
an unrelated successful queue run is not evidence for the change.

There is no pixel gate. Goldens were removed after measurement: readable images
differ between Linux and Windows by 0.9-1.1% of pixels, and blocking the text
out does not fix it, because obscuring removes glyph painting but not glyph
measurement — the rectangle it paints is sized from the measured text, so a
sub-pixel metric difference moves its edge a whole pixel. 32 of 165 images
still differed, worst on scripts that fall back to another font (Japanese, up
to 5.45%). Assert layout, spacing, and colour on the widgets instead. Do not
reintroduce goldens without accepting that only one host can verify them.
