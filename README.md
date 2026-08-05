# Coder

Flutter GUI and a pure-Dart AI coding-agent daemon. The daemon owns workspace,
agent, timeline, and approval state; desktop and mobile applications connect to
the same versioned WebSocket protocol.

## Development

```sh
dart pub get --enforce-lockfile
dart run melos verify
dart run melos verify:debug
```

See [`docs/testing.md`](docs/testing.md) for the individual TDD, contract,
widget, golden, coverage, architecture, and Debug E2E commands.

Run the standalone daemon. The seeded OpenAI provider reads
`OPENAI_API_KEY`; additional providers can use an environment variable or a
locally stored credential configured from the Settings screen:

```sh
dart run melos run run:daemon
```

The default endpoint is `ws://127.0.0.1:7337/ws`. Override the state/config
directory and listener with `TINYRACK_CODER_HOME` and
`TINYRACK_CODER_LISTEN`. Without an override, Linux uses the XDG config/state
directories, macOS uses Application Support, and Windows uses AppData.

The app shell does not require a daemon connection. Desktop enables its
app-owned embedded daemon by default, while mobile remains remote-only. Global
Settings can disable the embedded daemon and save any number of independent
`ws://` or `wss://` remote daemon profiles. Desktop Settings also controls
whether the embedded daemon listens only on `127.0.0.1` or on every IPv4
interface (`0.0.0.0`); changing it restarts only that app-owned daemon. Offline
profiles and the last selected host remain navigable.

Provider and Markdown Agent setup belongs to a connected daemon. Every client
uses one bearer token, which grants the complete daemon API for both local and
remote connections. `coder-cli` drives the same setup from a terminal against
an already running daemon, discovering its token from the same configuration
directory:

```sh
brew install tinyrack-net/tap/coder-cli   # or winget install tinyrack.coder-cli
coder-cli provider list
coder-cli agent apply reviewer --file reviewer.md
```

From a checkout, `dart run melos run:cli -- provider list` runs the same
commands without installing anything.

Desktop, mobile, and web use separate targets so that only the desktop
bootstrap can start a daemon. Run these commands from `apps/coder_app`:

```sh
flutter run -d linux -t lib/main_desktop.dart
flutter run -t lib/main_mobile.dart
flutter run -d chrome -t lib/main_web.dart
```

The web build is a client only, hosted at `https://coder.tinyrack.net`. It
connects to a daemon you run yourself, which has to allow the page's origin
first; see [`docs/remote-daemon.md`](docs/remote-daemon.md).

Release builds, packaging, and the winget and Homebrew channels are described
in [`docs/releasing.md`](docs/releasing.md).

The daemon intentionally does not implement TLS or certificate bypasses. Keep
it bound to loopback when terminating TLS in a local reverse proxy. Binding to
all interfaces exposes the plain daemon port, which must be isolated by the
operator's firewall when TLS is mandatory. See
[`docs/remote-daemon.md`](docs/remote-daemon.md) for Caddy/Nginx WebSocket,
authentication-header, and development-data reset examples.

See [`docs/mcp.md`](docs/mcp.md) for configuring external MCP servers, the
secret reference syntax, and the trust implications of a repository-declared
`.mcp.json`.
