---
name: setup-playbook
description: Configure which model each playbook role runs on. Edits the agent frontmatter in place. Use for /setup-playbook, "configure playbook models", or changing playbook's model choices.
---

# Setup playbook

Model routing lives in `agents/*.md` frontmatter, one file per role. There is no config file. This skill edits those files in place and tells the user to reload.

## Roles

| Agent file | Role | Default |
|---|---|---|
| `agents/playbook-agent.md` | Full style, any in-playbook delegate | `inherit` |
| `agents/code-worker.md` | Mechanical code. Feature and refactoring delegates, swarm workers | `sonnet` |
| `agents/judgment-worker.md` | Hard code. Bug fix, perf issue, hillclimb, and anything cross-cutting | `opus` |
| `agents/reviewer.md` | Read-only review. Interrogate lens A, arena and eval judging, blast-radius | `opus` |
| `agents/reviewer-bugs.md` | Read-only review, bugs and security lens. Interrogate lens B | `opus` |
| `agents/reviewer-quality.md` | Read-only review, maintainability lens. Interrogate lens C | `opus` |
| `agents/explorer.md` | Read-only recon. How explorer, why investigators, swarm read lanes | `sonnet` |
| `agents/advisor.md` | Second-opinion advisor at checkpoints | `opus` |
| `agents/ci-watcher.md` | Watch PR checks and report | `sonnet` |
| `agents/comment-sicko.md` | Comment deletion pass | `sonnet` |
| `agents/memory-updater.md` | Continual-learning memory writes | `inherit` |

## Steps

### 1. Read current state

Read the `model:` line from each agent file above. That is the current configuration. A file with no `model:` line runs on the parent's model, the same as `inherit`.

### 2. Confirm the changes

Show every role with its current model. Ask which to change with `AskUserQuestion`, not free text. Valid values:

- `sonnet`, `opus`, `haiku`. The plain aliases. Prefer these, since they follow the account's current mapping.
- `inherit`. The role runs on the parent's model, which is how a user on a single model stays on it.
- A full model id, when the user names one deliberately. Never invent one, and never write an id the user did not give you.

`effort:` is a second dial on the same frontmatter, valid values `low`, `medium`, `high`. Offer it only when the user asks for it.

### 3. Edit the frontmatter

Edit the `model:` line in each chosen file. Change nothing else. Do not add `model:` to a file that deliberately has none unless the user picks a real model for that role.

### 4. Confirm

Tell the user which files changed and that `/reload-plugins` (or a new session) picks the change up. Re-running this skill updates it.

### 5. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.
