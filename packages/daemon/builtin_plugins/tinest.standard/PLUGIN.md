---
api: 5
id: tinest.standard
version: 1.0.0
name: Tinest Standard Driver
entrypoint: main.lua
capabilities:
  - model.call
  - tools.list
  - tools.invoke
  - state.read
  - state.write
---

# Tinest Standard Driver

Provider-neutral streaming driver. The Agent definition and ordered extension
data remain inputs to this Lua handler; the daemon does not inject a harness
prompt or choose behavior from a model ID.
