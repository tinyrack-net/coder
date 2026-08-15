---
api: 5
id: tinest.goal
version: 1.0.0
name: Tinest Goal
entrypoint: main.lua
capabilities:
  - state.read
  - state.write
  - scheduler.manage
  - ui.publish
---

# Tinest Goal

Durable goal state, usage accounting inputs, serialized continuation, and
native status/dialog surfaces implemented through public SDK calls.
