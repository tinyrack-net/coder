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

Use the gear button in the connected app to configure multiple OpenAI or
OpenAI-compatible endpoints. Each provider can use Responses or Chat
Completions, discover model IDs through `/models`, and retain manually entered
models and capability overrides. Explicit model diagnostics make a small
streaming tool-call request and may incur provider charges.

Desktop and mobile use separate targets so the mobile bootstrap never starts a
daemon. Run these commands from `apps/coder_app`:

```sh
flutter run -d linux -t lib/main_desktop.dart
flutter run -t lib/main_mobile.dart
```

LAN mode is intentionally plain `ws://` for trusted local networks only. Bind a
standalone daemon to `0.0.0.0:7337` explicitly and provide a 256-bit token via
`TINYRACK_CODER_TOKEN`. Do not expose this listener to the public internet.
Remote clients can inspect the provider catalog but provider and credential
mutations are restricted to loopback connections.
