# MCP servers

Tinyrack Coder consumes external [Model Context Protocol][mcp] servers. The
daemon connects to them, publishes their tools alongside the built-in ones, and
calls them inside a turn. It does not expose an MCP server of its own: the
built-in tools are native `AgentTool`s, and wrapping them in a protocol would
only add serialization between the daemon and itself.

[mcp]: https://modelcontextprotocol.io

## Where servers are declared

Two files, one schema:

| Scope     | Path                          | Who owns it                     |
| --------- | ----------------------------- | ------------------------------- |
| `user`    | `<config>/v4/config.json`              | You. Coder reads and writes it. |
| `project` | `<worktree root>/.coder/config.json`   | The repository. Read-only.      |

`<config>` is the daemon configuration directory: `$XDG_CONFIG_HOME/tinyrack-coder`
on Linux, `~/Library/Application Support/Tinyrack Coder` on macOS, and
`%APPDATA%\Tinyrack Coder` on Windows.

```jsonc
{
  "schemaVersion": 3,
  "mcp": {
    "servers": {
      "github": {
        "enabled": true,
        "transport": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-github"],
        "env": { "GITHUB_TOKEN": "${secret:github.token}" }
      },
      "linear": {
        "transport": "http",
        "url": "https://mcp.linear.app/mcp",
        "headers": { "Authorization": "Bearer ${env:LINEAR_API_KEY}" }
      }
    }
  }
}
```

Rules the parser enforces, so a mistake fails loudly instead of half-working:

- A server id must match `^[a-z0-9][a-z0-9_-]*$`, be at most 40 characters, and
  contain no `__`. Ids become part of the tool name `mcp__<server>__<tool>`.
- `stdio` needs `command`. `args`, `env`, and `cwd` are optional; `cwd` must be
  absolute.
- `http` needs an `https` `url`. Plain `http` is accepted only for `localhost`
  and `127.0.0.1`, because anything else would put the headers on the wire in
  the clear.
- An unknown key is an error. A typo that silently does nothing is worse than a
  refusal.

Only the two transports in the current specification are implemented: stdio and
Streamable HTTP. The deprecated two-endpoint SSE transport is not.

## Secrets

Neither file ever holds a secret. Values in `env` and `headers` expand two
references at connect time:

- `${env:NAME}` reads the daemon process environment.
- `${secret:key}` reads a value stored in `v4/secrets.json`, which is written
  through the settings UI and never sent back to a client.

`$$` is a literal `$`; every other `$` is literal too, so `costs $5` needs no
escaping. An unset reference fails the connection by name rather than resolving
to an empty string and producing a confusing 401 later.

A committed `.coder/config.json` may not put a literal under a key whose name suggests a
credential (`token`, `key`, `secret`, `auth`, `password`, and similar). Those
must use a reference. This is the cheapest available guard against the most
common way a token reaches a public repository.

## Scope and precedence

A user server always wins a name collision. The project entry is reported as
`shadowed`, is never launched, and is labelled as such in the UI, so a
repository cannot quietly redirect a tool you configured for yourself.

Project servers are scoped to the worktree that declares them. They connect
lazily the first time a turn uses that worktree — so the first turn there runs
with your servers and the repository's join from the next one — and are released
after thirty minutes without use, so moving between repositories does not
accumulate child processes.

## Trust

**A project `.coder/config.json` runs without a prompt.** Opening a session in a cloned
repository is enough to launch whatever `command` it names, with your
environment. Treat cloning a repository as running its code, because with a
`.coder/config.json` present it is.

The settings screen always shows the file that declares a server, so what is
running is at least visible. If you work in repositories you do not trust,
review `.coder/config.json` before opening a session in them.

## Resources

Servers may publish *resources* — data they share for context, such as files,
database schemas, or application state — and *resource templates*, which take
parameters. A server advertises them through the `resources` capability, and
the client drains every page at connect time, refreshing on
`notifications/resources/list_changed`.

Three opt-in tools expose them to an agent:

| Tool | What it does |
| --- | --- |
| `list_mcp_resources` | Lists resources. Omit `server` to fan out across every visible server, unpaginated and sorted by server name; name one to page its resources with `cursor`. |
| `list_mcp_resource_templates` | The same, for parameterized templates. |
| `read_mcp_resource` | Reads one resource by `server` and `uri`. |

All three are `ToolRisk.read`, unlike MCP *tools*. `resources/read` is defined
by the specification as a side-effect-free fetch, whereas `tools/call` runs
whatever the server decided a tool should do.

A server's resources and templates are listed under its entry in MCP settings,
collapsed so a server publishing hundreds of them does not bury its errors and
diagnostics.

## Approval and risk

Every MCP tool carries `ToolRisk.dangerous`: what an external tool does cannot
be inferred from its name, so it is not classified as a read or a write. Under
`ask` and `workspaceWrite` an MCP call needs approval; under `readOnly` it is
denied. Built-in read tools remain always-on and never prompt.

MCP tool schemas are sent to the model as declared, not rewritten, and are
exempt from provider strict mode — a server's optional properties are its own
contract to define.

## Failure

A server that cannot start never breaks the daemon or a turn:

- Its state carries the error and the tail of its stderr, both shown in
  settings.
- Its tools drop out of the catalog, so the model is not offered something that
  cannot run.
- A call against a server that died mid-turn returns an error result the model
  can recover from, rather than failing the turn.

Reconnection backs off exponentially from one second to a minute with jitter.
Saving configuration reconciles by id, so an unchanged server keeps its live
connection instead of being restarted with the rest.

## Upgrading

Protocol v4 starts with a fresh configuration namespace. There is no v2/v3
reader or migration: configure servers in `v4/config.json` and reconnect
providers in `v4/secrets.json`. Preserved legacy files remain untouched until
an explicit legacy-cleanup operation is requested.
