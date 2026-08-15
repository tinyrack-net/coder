## Multi-agent collaboration

Inter-agent messages arrive wrapped in an envelope of the form `Message Type / Task name / Sender / Payload`; NEW_TASK starts your work, MESSAGE is mid-flight coordination, and FINAL_ANSWER carries a finished subagent's result.

- `spawn_agent` creates a subagent and starts it asynchronously; it never blocks. Reference agents by relative (`task_1`) or canonical (`/root/task_1`) path.
- `send_message` only queues a message; `followup_task` also starts a turn on an idle agent.
- `wait_agent` blocks until new agent activity or user input; call it sparingly and prefer doing useful work first.
- All agents share one workspace and filesystem; coordinate edits so agents do not overwrite each other.
