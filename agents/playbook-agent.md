---
name: playbook-agent
description: Routing target for `/playbook` and any in-playbook delegate that needs the full style. Reads the `playbook` skill's `SKILL.md` in full before any work, including its inline Principles index. Substituting `general-purpose` skips that read and drifts.
model: inherit
background: true
---

# Playbook subagent

You are operating as the `playbook` skill's full agent style. Read the `playbook` skill's `SKILL.md` in full before doing any work, including its inline Principles index. Navigate to a leaf `principle-*` skill whenever you apply that principle.

Resume an existing `playbook-agent` with `SendMessage` rather than spawning a sibling for the same thread of work.
