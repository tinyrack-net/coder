# Releasing

## Renaming the application

`packages/app/lib/src/app/app_identity.dart` is the source of truth for product
names and identifiers. Change it first, update the platform-local declarations
reported by `app_identity_test.dart`, then run `dart run melos generate` to
regenerate localized messages. The identity test also inventories protocol,
environment, installer, and release names so a rename cannot silently leave an
old identifier behind.

Coder ships as a desktop application, a standalone command-line client, a web
client, and an independently versioned relay server. An application `v<version>`
tag drives the desktop, CLI, and web artifacts through
`.github/workflows/pipeline.yml`; a `relay-v<version>` tag publishes the relay
container through `.github/workflows/relay-release.yml`.

## What is published

### Desktop application

| Platform | Artifacts | Channel |
| --- | --- | --- |
| Linux x64 | `.AppImage`, `.deb`, `.rpm`, `.tar.gz` | GitHub Releases |
| macOS x64 and arm64 | signed, notarized `.zip` | GitHub Releases, `brew install --cask tinyrack-net/tap/coder` |
| Windows x64 | `Coder-setup-win-x64.exe`, `.msix`, `.zip` | GitHub Releases, `winget install tinyrack.coder` |

Flutter publishes an SDK only for x64 hosts, so neither an arm64 Linux nor an
arm64 Windows runner can install it. macOS is the one platform with an arm64
SDK, which is why it is the only architecture pair here. Both arm64 desktop
targets become possible the day Flutter ships those SDKs.

### Command-line client

| Platform | Artifacts | Channel |
| --- | --- | --- |
| Linux x64 | `coder-cli-linux-x64.tar.gz` | GitHub Releases, `brew install tinyrack-net/tap/coder-cli` |
| macOS x64 and arm64 | signed, notarized `coder-cli-macos-<arch>.tar.gz` | GitHub Releases, `brew install tinyrack-net/tap/coder-cli` |
| Windows x64 | `coder-cli-windows-x64.zip` | GitHub Releases, `winget install tinyrack.coder-cli` |

The CLI's own code is plain Dart, but it shares a pub workspace with
`app`, so `dart pub get` resolves `flutter`, `flutter_test`, and
`integration_test` from the Flutter SDK. `build-cli` therefore installs Flutter
and is held to the platforms Flutter publishes an SDK for — which is why there
is **no Linux arm64 CLI**, and why `shipworld.yaml` names only three platforms
under `homebrew.platforms`. Taking `packages/app` out of the workspace is
what would bring that target back.

Since `coder-cli daemon start` hosts the daemon in-process, it carries the
database and provider stack and is built with `dart build cli` rather than
`dart compile exe`:

```
bundle/
  bin/coder-cli
  lib/libsqlite3.<ext>
  lib/libptyworld.<ext>
```

The CLI artifacts are therefore **archives, not bare executables**: the
executable resolves those two libraries from its sibling `lib/` directory. The
sqlite3 build hook downloads a precompiled library, so the build step needs
network access, not only `pub get`.

The Formula covers exactly the platforms listed in `homebrew.platforms`, so
Linux arm64 is absent rather than pointing at an artifact no runner builds.
Because the `coder-cli` target declares `payload.kind: directory`, shipworld
generates a Formula that installs the unpacked bundle into `libexec` and
symlinks `bin/coder-cli`; the symlink works because the executable's RPATH
resolves against its real path.

The Cask (`coder`) and the Formula (`coder-cli`) land in the same
`tinyrack-net/homebrew-tap` commit.

### Android application

| Platform | Artifact | Channel |
| --- | --- | --- |
| Android | signed universal `Coder-android-universal.apk` | GitHub Releases |

The APK uses the mobile entrypoint and is built once for all supported Android
ABIs. Google Play App Bundles and Play App Signing are not part of this release
channel.

### Web client

| Artifact | Channel |
| --- | --- |
| `flutter build web` output | `tinyrack-coder` Worker at `https://coder.tinyrack.net` |

`packages/app/wrangler.jsonc` binds the custom domain, so the deploying API
token needs Workers Routes and Zone read on `tinyrack.net` alongside Workers
Scripts edit. The hostname is also the daemon's default allowed origin
(`defaultAllowedOrigins` in `packages/daemon/lib/src/config.dart`);
changing one without the other locks every browser client out.

The web build is a static client with no server of its own; it connects to a
daemon the user runs. `web-build` compiles it on every pull request and main
push, but `deploy-web` publishes only for an application `v<version>` tag. The
GitHub Release waits for that deployment, so one application release cannot
claim success while `https://coder.tinyrack.net` is still on an older commit.

`web-build` runs on every pull request and is part of the quality gate. That
is deliberate: a `dart:io` import reaching the web entrypoint compiles fine
everywhere else and only fails there, so without it the breakage would surface
at release time.

`cli-verify` exists for the same reason and is also in the gate. It builds the
CLI bundle on all four release platforms and hosts a daemon from it, sharing
the `build-cli-bundle` and `smoke-cli-bundle` composite actions with
`build-cli` so the two cannot drift. Before it existed, nothing built the CLI
outside a tag, and two release-path breakages reached `main` that way: a
workspace resolution failure that broke every target, and a smoke test left on
a stale flag order. Signing, notarization, archiving, and Formula generation
still happen only in `build-cli`, because they need secrets a fork pull request
never receives.

See [`remote-daemon.md`](remote-daemon.md) for the origin allowlist a daemon
needs before a browser can reach it.

### Relay server

| Artifact | Channel |
| --- | --- |
| `linux/amd64` and `linux/arm64` OCI image | `ghcr.io/tinyrack-net/coder-relay` |

The relay has its own version in `packages/relay/pubspec.yaml`. A
`relay-v<version>` tag tests the relay packages, verifies the tag through
Shipworld, builds and exercises the real container, and publishes one
multi-platform manifest under both `v<version>` and `latest`. The workflow also
adds OCI source/version/revision labels and a GitHub artifact attestation. It
does not create a GitHub Release or publish to Docker Hub.

The Docker build pins the Dart and distroless multi-platform manifests and uses
the committed `packages/relay/docker/pubspec.lock` with
`dart pub get --enforce-lockfile`. Keep that lock current whenever either relay
pubspec changes.

Production deployment is owned by the `tinyrack-net/infrastructure` GitOps
repository, not by a second manifest in this repository. Flux selects only
immutable `v<version>` image tags and updates the single-replica Deployment;
`latest` is a convenience pull tag and is never a rollout source. The relay's
registry is process-local, so the Deployment must not overlap two replicas
until shared state or `serverId`-consistent routing exists.

WinGet consumes the Inno Setup `setup.exe`; the MSIX exists for the Microsoft
Store path and is not yet submitted. There is no `.msixbundle` because there is
only one Windows architecture to bundle.

The MSIX step is skipped unless `MSIX_IDENTITY_NAME` is set, so a release
without those three secrets still produces everything winget and the GitHub
Release need. Setting them turns the step back on with no workflow change.

## Cutting a release

Versions come from `packages/app/pubspec.yaml` and are mirrored into
`packages/app/lib/src/version.g.dart`,
`packages/daemon/lib/src/version.g.dart`, and
`packages/cli/lib/src/version.g.dart` by the release tool. Never edit
those three by hand.

`shipworld.yaml` declares three targets. `coder` owns the application version
source and writes all three application version files. The `coder-cli` target
exists so the Formula can be generated with its own product metadata and reads
the same version, which is why one application tag ships a matching desktop
app, daemon, and CLI. `relay` is the other releasable target and reads only the
independent relay pubspec.

```sh
git clone https://github.com/tinyrack-net/dart-packages.git \
  .dart_tool/tinyrack-dart-packages
git -C .dart_tool/tinyrack-dart-packages checkout \
  e07124e15bd7495818bd34ed655f39e5a4bcc35b
dart pub get --directory .dart_tool/tinyrack-dart-packages

# Writes the version files and commits; open the result as a pull request.
dart run .dart_tool/tinyrack-dart-packages/packages/shipworld/bin/shipworld.dart \
  release prepare coder=minor    # or =patch / =major

# After the pull request merges, from an up-to-date main:
dart run .dart_tool/tinyrack-dart-packages/packages/shipworld/bin/shipworld.dart \
  release finalize coder --push
```

`finalize` refuses unless `HEAD` matches `origin/main`, and creates a
GPG-signed tag. Pushing `v<version>` runs the packaging and publish jobs.
Release notes are generated by `gh release create --generate-notes`; there is
no changelog file.

The relay follows the same prepare/finalize discipline but uses its independent
target and tag:

```sh
# Writes packages/relay/pubspec.yaml and commits; open a pull request.
dart run .dart_tool/tinyrack-dart-packages/packages/shipworld/bin/shipworld.dart \
  release prepare relay=patch    # or =minor / =major

# After that pull request merges, from an up-to-date main.
dart run .dart_tool/tinyrack-dart-packages/packages/shipworld/bin/shipworld.dart \
  release finalize relay --push
```

The initial publication uses the existing `0.1.0` version and therefore starts
at `relay-v0.1.0`. New GHCR packages begin private; after that first workflow
finishes, make `coder-relay` public once, verify an anonymous pull, and leave it
public for Flux and external consumers.

## Required secrets

All are repository secrets on `tinyrack-net/coder`.

| Secret | Used by | Same value as other repositories |
| --- | --- | --- |
| `APPLE_CERTIFICATE` | macOS signing | yes |
| `APPLE_CERTIFICATE_PASSWORD` | macOS signing | yes |
| `APPLE_DEVELOPER_ID` | macOS signing | yes |
| `APPLE_NOTARY_KEY_ID` | notarization | yes |
| `APPLE_NOTARY_ISSUER_ID` | notarization | yes |
| `APPLE_NOTARY_KEY_P8_BASE64` | notarization | yes |
| `ANDROID_KEYSTORE_BASE64` | Android APK signing keystore | no |
| `ANDROID_KEYSTORE_PASSWORD` | Android keystore password | no |
| `ANDROID_KEY_ALIAS` | Android signing key alias | no |
| `ANDROID_KEY_PASSWORD` | Android signing key password | no |
| `HOMEBREW_TAP_TOKEN` | pushing the Cask to the tap | yes |
| `WINGET_TOKEN` | the winget-pkgs pull requests | yes |
| `CLOUDFLARE_API_TOKEN` | the web deployment | organisation-wide |
| `CLOUDFLARE_ACCOUNT_ID` | the web deployment | organisation-wide |
| `MSIX_IDENTITY_NAME` | MSIX identity, optional | no, `tinyrack.coder` |
| `MSIX_PUBLISHER` | MSIX identity, optional | yes, matches the signing certificate |
| `MSIX_PUBLISHER_DISPLAY_NAME` | MSIX identity, optional | yes |

The two Cloudflare values are read as either a secret or an Actions variable,
so the deployment works from whichever organisation tab holds them. Prefer the
secret for `CLOUDFLARE_API_TOKEN`: an Actions variable is not masked in logs,
and that token can deploy Workers.

Create and retain the Android key outside the repository. For example, a JKS
key with a long-lived RSA certificate can be created interactively with:

```powershell
keytool -genkeypair -v -keystore coder-release.jks -storetype JKS `
  -keyalg RSA -keysize 4096 -validity 10000 -alias coder-release
```

Encode the complete keystore file, then register the result and the three
credentials as repository secrets without writing their values into the shell
history:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes((Resolve-Path '.\coder-release.jks'))
) | gh secret set ANDROID_KEYSTORE_BASE64 --repo tinyrack-net/coder
gh secret set ANDROID_KEYSTORE_PASSWORD --repo tinyrack-net/coder
gh secret set ANDROID_KEY_ALIAS --repo tinyrack-net/coder
gh secret set ANDROID_KEY_PASSWORD --repo tinyrack-net/coder
```

GitHub secrets cannot be read back after registration. Keep the original JKS
and its credentials in the user's own durable storage: every future update of
`net.tinyrack.coder` must be signed by the same key. Use passwords without
newlines because the CI job writes one property per line into the ignored
`android/key.properties` file on its ephemeral runner.

The values marked as shared are identical across `dotweave`, `proxer`, and
this repository, so promoting them to organisation secrets removes the copying
entirely. The Android signing values and `MSIX_IDENTITY_NAME` remain
product-specific.

Signing is skipped rather than failed when the Apple secrets are absent: the
app is ad-hoc signed and left un-notarized, which is what non-tag builds do
anyway. The MSIX step only runs on tags.

The `setup.exe` is currently unsigned, so Windows SmartScreen warns on first
run until a code-signing certificate is bought. An unsigned MSIX cannot be
sideloaded without developer mode.

## Verifying a release locally

```sh
dart run melos build:linux:release
dart run .dart_tool/tinyrack-dart-packages/packages/shipworld/bin/shipworld.dart \
  package linux deb coder \
  --input packages/app/build/linux/x64/release/bundle \
  --output dist/coder-linux-x64.deb --arch amd64
sudo dpkg -i dist/coder-linux-x64.deb && coder
```

The deb installs the bundle under `/usr/lib/coder` and links `/usr/bin/coder`
at it. That link works because the executable's `RUNPATH` is `$ORIGIN/lib` and
the dynamic loader resolves it against the real path, not the link.

Linux needs `libayatana-appindicator3-dev` to build and a StatusNotifier host
to show the tray icon; on GNOME that means the AppIndicator extension.

The CLI and its Formula need no Flutter toolchain:

```sh
dart run melos build:cli
./dist/bundle/bin/coder_cli --version

# The Formula wants one artifact per platform in `homebrew.platforms`.
mkdir -p dist/homebrew
for target in macos-arm64 macos-x64 linux-x64; do
  cp -R dist/bundle "dist/homebrew/coder-cli-$target"   # real builds per host
done
shipworld package homebrew formula coder-cli \
  --artifacts-dir dist/homebrew --output dist/coder-cli.rb
```

Copying one bundle across all three names only checks that the Formula renders;
a real release builds each on its own runner.
