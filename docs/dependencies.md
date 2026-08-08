# Dependency upgrades

The workspace resolves as a single Dart pub workspace with one `pubspec.lock`,
so every package shares one dependency resolution. A constraint anywhere —
including one the Flutter SDK imposes — constrains everything.

Run `flutter pub outdated` from the repository root. It will report packages
that look upgradable but are not. The sections below record why, so the answer
does not have to be rediscovered each time.

## Ceiling 1: `analyzer` is capped below 13 by the Flutter SDK

`flutter_test` in the pinned Flutter SDK depends on an **exact** `test_api`
version. That pin propagates through the whole workspace:

```
flutter_test → test_api 0.7.11 → test ≤ 1.31.0 → analyzer <13.0.0
```

Everything below needs `analyzer ^13` and therefore cannot move until a Flutter
stable ships a `flutter_test` that allows `test_api` 0.7.13:

| Package | Held at | Wants |
| --- | --- | --- |
| `flutter_riverpod`, `riverpod`, `riverpod_annotation`, `riverpod_generator` | 3.3.2 / 4.0.3 / 4.0.4 | 3.4.2 / 4.0.6 / 4.0.8 |
| `freezed` | 3.2.6-dev.1 | 4.0.0-dev.3 |
| `build_runner` | 2.15.1 | 2.16.0 |
| `drift_dev` | 2.34.0 | 2.34.5 |
| `test` | 1.31.0 | 1.31.2 |
| `mockito` | 5.6.4 | 5.8.1 |

`melos` is held at 7.8.1 by the same chain, one step removed: `melos` 7.8.2 and
8.x require `cli_util ^0.5.0`, while `drift_dev` 2.34.0 requires `cli_util
^0.4.0`. `drift_dev` 2.34.1 widened that constraint but also moved to
`analyzer ^13`, so `melos` unblocks only once `analyzer` does.

`dependency_validator` 5.0.5 independently caps `analyzer <13.0.0`. It is not
the binding constraint today, but it becomes the next ceiling the moment
Flutter's lifts — check it first when revisiting this.

`drift` itself is not blocked: `drift_dev` 2.34.0 accepts `drift >=2.30.0
<2.35.0`, so the runtime package tracks the 2.34.x patch line independently of
its generator.

## Ceiling 2: `win32` is capped below 6 by `launch_at_startup`

`launch_at_startup` 0.5.1, its latest release, requires `win32_registry ^2.0.0`,
which requires `win32 ^5`. That blocks:

- `flutter_secure_storage` 11.0.0 (via `flutter_secure_storage_windows ^4.2.2` → `win32 ^6.0.1`)
- `share_plus` 13.x (`win32 ^6.0.1`); 12.0.2 is the highest that still allows `win32 ^5`
- `win32_registry` 3.x

This one clears when `launch_at_startup` publishes a `win32_registry ^3`
release, independently of the Flutter SDK.

## Packages the Flutter SDK owns

`meta`, `matcher`, `vector_math`, `package_config`, and `intl` (pinned exactly
by `flutter_localizations`) are resolved from SDK pins. Do not add constraints
that fight them; they move when the SDK moves.

The same pin is why `hooks` is held at 2.0.2 and `native_toolchain_c` at 0.19.2:
`hooks` 2.1.0 requires `meta ^1.19.0`, and the SDK pins `meta` to 1.18.0.

## Tinyrack Git sources

`tinyrack_ui`, `cliweave`, `dartage`, `lua_tool_runtime`, `ptyworld`,
`shipworld`, `dropwell`, and `termworld` come from `tinyrack-net` Git
repositories at exact 40-character commit SHAs, never from pub.dev and never
from a moving ref. `dart run melos
tinyrack-sources:check` enforces this against both the manifests and the
lockfile. `dropwell` and `termworld` both live in
`tinyrack-net/flutter-packages` and Coder pins them to the same merge SHA.

`cliweave`, `lua_tool_runtime`, and `ptyworld` all live in
`tinyrack-net/dart-packages`, and CI checks that repository out **once** for
the whole pipeline. So four values
must move together, always to the same SHA:

1. `ref` for `cliweave` in `packages/coder_cli/pubspec.yaml`
2. `ref` for `lua_tool_runtime` in `packages/coder_daemon/pubspec.yaml`
3. `ref` for `ptyworld` in `packages/coder_daemon/pubspec.yaml`
4. `TINYRACK_DART_PACKAGES_REF` in `.github/workflows/pipeline.yml`

Updating only some of them fails in a checkout step far from the cause —
typically as a missing package during resolution rather than as a version
mismatch.

Pin to a **merge commit on `main`**, not a pull-request branch head. If the
upstream repository squash-merges, a branch SHA becomes unreachable and the
next `pub get` fails on a commit that no longer exists.

## After any upgrade

Beyond `dart run melos verify` and `dart run melos verify:debug`, run
`dart run melos build:cli` whenever `hooks`, `code_assets`, or
`native_toolchain_c` change. `ptyworld`'s build hook also runs under plain
`dart test`, but `build:cli` is the only local step that produces the
release-shaped bundle, where the CLI resolves `libptyworld` from a sibling
`lib/` directory rather than from the build's own asset layout. Windows and
macOS build hook behaviour is covered only by the platform jobs in
`.github/workflows/pipeline.yml`, and by the `ptyworld` matrix in
`tinyrack-net/dart-packages`.
