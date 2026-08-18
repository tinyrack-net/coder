---
api: 5
id: tinest.context
version: 1.0.0
name: Tinest Context
entrypoint: main.lua
capabilities:
  - ui.publish
---

# Tinest Context

Provider-neutral context accounting and declarative driver actions. The tools
do not mutate provider history themselves; the selected Agent driver decides
how reset and compaction actions alter its durable context.
