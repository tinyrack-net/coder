# Architecture

Tinyrack Coder uses one authoritative daemon and multiple thin clients. The
desktop app normally starts that daemon in a separate isolate; the standalone
binary starts the same `DaemonApplication` in its own process. Android and iOS
compile `main_mobile.dart`, whose bootstrap can only create a remote
`CoderClient`.

```text
coder_app -> coder_client -> coder_protocol
    |                            ^
    +-- desktop only             |
         coder_daemon -> coder_agent -> coder_provider_openai
              |
              +-- Drift / SQLite
```

## Package boundaries

- `coder_protocol`: platform-neutral, generated request/response and domain
  DTOs for protocol version 2.
- `coder_client`: authenticated JSON-RPC 2.0 over WebSocket, reconnect, and
  sequence-based timeline catch-up. `json_rpc_2` owns request correlation,
  notifications, and structured transport errors.
- `coder_agent`: provider-independent turn loop, approval policy, cancellation,
  path-confined coding tools, and strict tool schemas.
- `coder_provider_openai`: direct Responses and Chat Completions streaming
  adapters plus OpenAI-compatible provider/model presets. Responses requests
  use `store: false`; encrypted reasoning items remain opaque daemon-owned
  conversation state.
- `coder_daemon`: composition root, feature-scoped Drift DAOs, lifecycle
  recovery, bearer authentication, WebSocket RPC server, embedded isolate,
  and CLI.
- `coder_app`: feature-scoped Riverpod `AsyncNotifier` application state,
  typed go_router navigation, Reactive Forms settings, and adaptive Material 3
  UI. Controllers depend only on the transport-neutral `CoderApi` port.

Dependencies point inward through DTOs and interfaces. `coder_agent` does not
read databases or call the network. The daemon is the only package allowed to
combine a provider, repositories, tools, and transports.

## Runtime invariants

- Client-generated UUIDs make workspace, agent, and turn creation idempotent.
- Timeline sequence numbers increase per agent. Events are committed to SQLite
  before they are broadcast; reconnect starts after the last observed sequence.
- Turns are sequential and model parallel tool calls are disabled.
- Provider-specific wire objects are normalized into canonical user,
  assistant/tool-call, and tool-result conversation items before persistence.
- An agent's provider and model can change only before its first turn.
- Read tools are automatically allowed. Write and command tools follow the
  agent's `readOnly`, `ask`, or `workspaceWrite` policy.
- Every file path is resolved against the canonical workspace root. Lexical and
  symlink escapes are rejected before I/O.
- A daemon restart marks running turns interrupted and cancels pending
  approvals; it never replays a tool automatically.
- API keys and plaintext bearer tokens are not written to SQLite, logs,
  timeline events, broadcasts, or RPC responses. Stored credentials live in
  owner-restricted JSON files under the platform config directory; provider
  keys may instead reference daemon environment variables.
- Every authenticated client may update Provider and Markdown Agent settings.
  The single bearer token grants the complete daemon API; there are no roles or
  location-based permissions.

## Desktop residency

The desktop app owns the embedded daemon, so closing its window hides it to the
platform tray instead of quitting; only the tray's Quit row stops the daemon and
ends the process. `DesktopWindow`, `TrayIcon`, and `AutostartRegistration` are
typed ports supplied by `main_desktop.dart`; mobile passes null and never builds
the shell. Tray labels and the embedded-daemon status row are rebuilt from
`AppLocalizations` and `HostRegistryState`, so they follow the selected
language. Native tray calls are serialized because the icon must exist before a
menu can be attached to it.

General settings register the app as a login item. "Start minimized" is recorded
as a `--start-minimized` argument on that registration, and the app starts
hidden only when both the stored preference and that argument are present, so a
launch the user started always shows a window.

Because a second instance would bind a second daemon over the same data, the
Linux runner is single-instance and later launches raise the running window.
That also means `flutter run -d linux` exits immediately while another build of
the app is running; stop it first.

Linux requires `libayatana-appindicator3-dev` to build and a StatusNotifier host
(on GNOME, the AppIndicator extension) to show the icon. macOS registers its
login item through `SMAppService`, which sets the deployment target to 13.0.

## Network scope

The default listener is loopback-only. Desktop Settings can restart the
app-owned embedded daemon on either `127.0.0.1` or all IPv4 interfaces
(`0.0.0.0`); standalone daemons retain their CLI/environment listener. The
client accepts both `ws://` and `wss://` endpoints without applying transport
policy. Public reachability, firewalling, TLS termination, relay, accounts, and
E2EE remain the operator's responsibility.
