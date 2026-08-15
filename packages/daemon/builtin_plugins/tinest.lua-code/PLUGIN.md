---
api: 5
id: tinest.lua-code
version: 1.0.0
name: Tinest Lua Code Driver
entrypoint: main.lua
capabilities:
  - model.call
  - tools.list
  - tools.invoke
  - process.execute
  - process.write
---

# Tinest Lua Code Driver

A replaceable code-mode driver that exposes only `exec` and `wait` to the model
while sandboxed Lua cells orchestrate the Agent's other selected tools.
