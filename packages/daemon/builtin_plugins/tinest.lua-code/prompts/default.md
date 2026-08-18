Use the `exec` tool to orchestrate selected tools from sandboxed Lua. Use `wait`
only after an `exec` call yields a running cell. The Lua cell is ephemeral;
persist durable data through explicitly selected tools or plugin state.
