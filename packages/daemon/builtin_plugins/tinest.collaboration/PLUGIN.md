---
api: 5
id: tinest.collaboration
version: 1.0.0
name: Tinest Collaboration
entrypoint: main.lua
capabilities:
  - collaboration.spawn
  - collaboration.message
  - collaboration.wait
  - collaboration.interrupt
  - collaboration.list
  - ui.publish
---

# Tinest Collaboration

Subagent lifecycle and messaging tools plus a declarative collaboration status
surface. Every operation is routed through the public capability broker.
