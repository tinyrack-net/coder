---
name: tinyrack-tinest-design-guidelines
description: Enforce Tinyrack's Flutter design system in Tinest using the public tinyrack_ui Git source pinned to an exact commit. Use for any Flutter UI implementation, modification, refactor, review, styling, layout, component selection, theme work, or pixel-changing test update in packages/app, including deciding whether a missing reusable primitive, token, or variant belongs upstream.
---

# Tinest Design Guidelines

Build every Tinest interface from the public `tinyrack_ui` package pinned to an
exact commit in `tinyrack-net/design`. Keep product-specific composition in
Tinest and reusable visual contracts in the Tinyrack design system.

## Inspect Before Editing

1. Read the consumer `pubspec.yaml`, lockfile, `.dart_tool/package_config.json`,
   existing imports, and neighboring widgets.
2. Inspect the resolved Git revision's README, public
   `lib/tinyrack_ui.dart` exports, component documentation, theme, and tokens.
   Treat that installed release as the source of truth; do not infer APIs from
   memory or an unreleased checkout.
3. Search the public API for an existing component, typed variant, semantic
   color, or token before composing a replacement.
4. Configure and preserve `TinyrackTheme.light()` and
   `TinyrackTheme.dark()`. Import only:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:tinyrack_ui/tinyrack_ui.dart';
   ```

## Enforce Components and Tokens

- Use the public TR component whenever one represents the required control or
  surface. Do not recreate it with Material, Cupertino, or application-local
  painting and styling.
- Use public Tinyrack tokens for every visual design decision: colors,
  foregrounds, padding, margin, gaps, dimensions, typography, font sizes,
  weights, line heights, radii, borders, shadows, elevation, opacity, icon
  sizes, durations, and curves. This includes `TRSpacing`, `TRTypography`,
  `TRRadii`, `TRMotion`, `TRShadows`, `TRMeasurements`, and semantic values
  exposed by the Tinyrack theme.
- Do not introduce visual numeric literals, arbitrary `Color`, `TextStyle`,
  `EdgeInsets`, `Radius`, `BoxShadow`, `Duration`, or application-local design
  constants. Construct Flutter value objects from public tokens when the
  package does not expose the complete object.
- Permit a literal only when it is structural rather than a visual choice:
  zero, full expansion, a runtime-computed value, viewport constraints,
  content-derived geometry, or a mathematical ratio. Do not use this exception
  to approximate a missing token.
- Preserve the package's light/dark colors, English/Korean/Japanese IBM Plex
  typography, text scaling, text direction, focus visibility, keyboard and
  pointer behavior, semantics, and disabled, loading, readonly, invalid, hover,
  and pressed states.
- Never import `package:tinyrack_ui/src/...`, edit the pub cache, or use a path
  dependency, moving Git ref, or `dependency_overrides`. Consume the public
  repository with its canonical package path and an exact 40-character commit.

## Decide Ownership

Keep a product-specific composite widget in Tinest when its API expresses Tinest
domain concepts and it can be assembled entirely from public TR components and
tokens.

Move a capability upstream before continuing when any of these is true:

- a reusable visual or interaction primitive is missing;
- a general accessibility, focus, keyboard, overlay, or state contract would
  otherwise be implemented in Tinest;
- an existing TR component needs a generally useful variant or behavior;
- a visual decision has no suitable public token; or
- the component has a credible use outside Tinest and does not expose Tinest
  domain concepts.

Do not upstream a one-off product workflow merely to avoid a local composite.
Do not work around a missing upstream capability with a private clone, wrapper
that changes its contract, or temporary design literal.

## Ship a Missing Upstream Capability

Pause only the consumer implementation. The user has authorized this workflow
through merge, release, and reintegration; do not request another approval.

1. Resolve the canonical checkout and create a collision-free worktree from the
   latest remote main:

   ```bash
   cd ~/Workspaces/tinyrack/design
   git fetch origin main
   git worktree list
   git branch --list 'flutter-<change-slug>'
   git worktree add -b flutter-<change-slug> ../design-<change-slug> origin/main
   cd ../design-<change-slug>
   pnpm install
   cd packages/ui_flutter
   flutter pub get
   ```

2. Read the worktree's `AGENTS.md`, package manifest, README, public exports,
   neighboring components, generated-token workflow, tests, documentation, and
   publish workflow. Load and follow every applicable upstream skill required
   by its `AGENTS.md`, including `$tinyrack-component-development` and
   `$tinyrack-package-release` for a released component change.
3. Add a failing test for the missing contract before production code. Define a
   typed public API that is independent of Tinest terminology. Implement it under
   `packages/ui_flutter/lib/src/`, export it through `lib/tinyrack_ui.dart`, and
   update examples and English, Korean, and Japanese documentation when
   user-facing behavior changes. Generate tokens through the repository
   workflow; never edit generated token files.
4. Update `packages/ui_flutter/CHANGELOG.md` and version in the same PR. Use a
   patch for a backward-compatible defect correction and a minor version for a
   new public component, token, variant, or other public contract addition.
5. Run focused tests while iterating, then the upstream-required Flutter gate:

   ```bash
   pnpm flutter:verify
   ```

   Exercise affected light/dark, locale, accessibility, text-scale,
   interaction, and platform states. Run the repository's visual parity check
   when appearance or interaction is shared with the React package, and run
   affected platform builds when platform behavior or assets change.
6. Commit and push the branch, open a ready PR against
   `tinyrack-net/design:main`, and monitor the required `CI gate`. Fix root
   causes and repeat verification until it is green. Do not weaken tests,
   bypass branch protection, or use an admin override.
7. Because repository auto-merge is disabled, squash-merge the green PR with
   `gh pr merge --squash`. Record the exact merge commit. Do not merge while a
   required check is pending or failing.
8. Record the exact squash-merge commit and verify it is reachable from the
   public `tinyrack-net/design` repository. Tags and pub.dev publishing may
   continue for other consumers, but Tinest does not wait for publication.
9. Remove the completed upstream worktree, update Tinest's `tinyrack_ui` Git
   `ref` to that exact merge commit, run `flutter pub get`, and resume the
   original consumer change.

Continue autonomously through correctable test, CI, and review failures. Stop
and report the exact blocker only when required authentication or permissions
are absent, an external service failure is not recoverable, or resolving the
failure would require an unrelated product decision.

## Verify the Consumer

- Add widget coverage for UI behavior and update the canonical Linux golden
  whenever pixels change.
- Verify relevant light/dark, English/Korean/Japanese, text-scale, keyboard,
  pointer, focus, semantics, loading, error, and constrained-layout states.
- Follow `AGENTS.md`, `docs/testing.md`, and `$verify-tinest-workspace` for the
  complete Tinest gates. Do not report completion while token literals, private
  package imports, or local recreations of public TR components remain in the
  changed surface.
