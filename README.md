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
`ws://` or `wss://` remote daemon profiles. Offline profiles and the last
selected host remain navigable.

Provider setup belongs to a connected daemon. Embedded clients carry a separate
local-admin token and can mutate provider credentials; ordinary remote clients
carry only the bearer token and see provider settings read-only.

Desktop and mobile use separate targets so the mobile bootstrap never starts a
daemon. Run these commands from `apps/coder_app`:

```sh
flutter run -d linux -t lib/main_desktop.dart
flutter run -t lib/main_mobile.dart
```

The daemon intentionally does not implement TLS or certificate bypasses. Keep it
bound to loopback and terminate TLS in a reverse proxy for remote access. See
[`docs/remote-daemon.md`](docs/remote-daemon.md) for Caddy/Nginx WebSocket,
authentication-header, and development-data reset examples.
