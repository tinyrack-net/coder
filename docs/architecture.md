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
         coder_daemon -> coder_agent
              |
              +-- provider infrastructure -> OpenAI-compatible APIs
              +-- MCP infrastructure -> external MCP servers
              +-- Drift / SQLite
```

## Package boundaries

- `coder_protocol`: platform-neutral, feature-scoped generated models,
  requests, responses, events, and typed procedure descriptors for protocol
  version 4.
- `coder_client`: authenticated JSON-RPC 2.0 over WebSocket, reconnect, and
  sequence-based timeline catch-up. Its root `CoderApi` exposes lifecycle and
  feature APIs such as `sessions`, `providers`, and `mcp`; each feature owns
  its typed update streams.
- `coder_agent`: provider-independent turn loop, approval policy, cancellation,
  path-confined coding tools, and strict tool schemas. It has no internal
  package dependency and exposes every filesystem, process, network, clock,
  and identity effect as a typed port.
- `coder_daemon`: feature-first domain/application/infrastructure/transport
  modules, provider and MCP adapters, Drift persistence, lifecycle recovery,
  bearer authentication, WebSocket RPC host, and embedded isolate.
- `coder_cli`: standalone daemon composition and feature-API command surface.
- `coder_app`: feature-scoped Riverpod `AsyncNotifier` application state,
  typed go_router navigation, and adaptive Tinyrack UI. Controllers depend only
  on injected ports such as the transport-neutral `CoderApi`.

Dependencies point inward through DTOs and interfaces. `coder_agent` does not
read databases or call the network. The daemon is the only package allowed to
combine a provider, repositories, tools, and transports.

The v4 WebSocket endpoint is `/v4/ws` with subprotocol
`tinyrack.coder.v4`. `system.hello` requires protocol major 4 and revision 0.
State and config start fresh under their respective `v4` directories; v2 and
v3 data are neither read nor removed by normal startup or reset. Only the
explicit legacy-cleanup operation may target those preserved namespaces.

## Flutter application boundaries

The Flutter client is organized by user-facing feature rather than by a global
pages/controllers/widgets split. Each feature owns only the layers it needs:
`application` for Riverpod state and commands, optional pure `domain` rules,
`infrastructure` adapters, and `presentation` pages and widgets. App startup,
provider overrides, typed routes, and cross-feature shells live under
`lib/src/app`; feature-neutral helpers and UI composites live under
`lib/src/shared`.

Dependencies flow from presentation to application and domain. Domain code is
framework-independent, application code cannot import Flutter widgets,
navigation, or platform plugins, shared code cannot depend on a feature, and a
feature cannot import another feature's page or widget. Cross-feature screen
composition is performed by the app shell. These rules are executable in
`ArchitectureVerifier` and run as part of `melos verify`.

Riverpod controllers are the Flutter equivalent of feature stores and actions;
they retain their `Controller` naming. The central typed router owns URL shape,
while route targets remain feature pages or app-owned cross-feature shells.
The app consumes `CoderApi` and `coder_protocol` DTOs directly because they are
already transport-neutral contracts. A repository or use-case is added only
for an app-owned source of truth or genuinely shared, multi-source logic.

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
Linux and Windows runners are single-instance and later launches raise the
running window. Linux keys that on the `GApplication` ID; Windows takes a mutex
in the `Local\` namespace, which is scoped to the logon session and so matches
the scope of the `%LOCALAPPDATA%` daemon home. Setting
`TINYRACK_CODER_ALLOW_MULTIPLE_INSTANCES` opts a run out, which is how the E2E
shards keep their own process. That also means `flutter run -d linux` exits
immediately while another build of the app is running; stop it first.

The Windows installer names the same mutex in `AppMutex`, so it closes a
tray-resident copy before replacing files instead of leaving it holding the
daemon home, and it starts the app with `runasoriginaluser` so a per-machine
install does not launch it with the administrator's `%LOCALAPPDATA%`.

When the daemon home is locked anyway, startup fails with a typed
already-running reason rather than the operating system's lock error, and the
settings alert offers the guidance and the raw diagnostic for a bug report.

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
