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
- Credential writes are accepted only from a loopback WebSocket peer. Remote
  clients receive redacted configuration and capability status.

## Network scope

The default listener is loopback-only. LAN mode must be explicitly bound to
`0.0.0.0` with a stable 256-bit token. Version 1 LAN traffic is plain WebSocket
and is intended only for a trusted local network. Public internet exposure,
TLS termination, relay, accounts, and E2EE are deliberately outside this
milestone.
