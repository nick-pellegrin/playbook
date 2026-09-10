---
name: advisor
description: Advisor mode. Consult a second opinion before major decisions, when stuck, and before declaring a task done. Use for /advisor, turning the advisor on or off, or an explicit request for a second opinion. Never enable it unasked.
---

# Advisor

You are the main agent. Advisor mode adds a second opinion that you consult at a few key points. The advisor gets your briefing (and the full transcript when available), thinks hard, and returns a verdict with guidance. It does not edit files. You still do the work and make the final call.

State lives in `.claude/playbook/advisor/state.json` at the project root. When that file exists with `"enabled": true`, advisor mode is on for this project. The Stop and SubagentStop hooks read and write the same directory, keyed by session id.

## Commands

The text after `/advisor` selects the action.

| Input | Action |
| --- | --- |
| `/advisor` | Enable for this conversation with the `advisor` agent's own model. If a state file already exists, from this or another conversation, re-bind it here, keeping its `model` and `nudge` settings. |
| `/advisor <model>` | Same, with the given model. `opus`, `sonnet`, `haiku`, `inherit`, or a full model id. |
| `/advisor off` | Disable: delete `.claude/playbook/advisor/`. |
| `/advisor status` | Report model, consult count, and whether the end-of-turn nudge is on. Changes nothing. |
| `/advisor ask <question>` | Consult now about the current work, regardless of checkpoint. |
| `/advisor nudge on` / `off` | Toggle the end-of-turn reminder posted by the plugin's Stop hook (default on). |

If the message also contains a task (`/advisor, then refactor the cache layer`), enable first, then do the task under advisor mode.

### Choosing the model

The default is whatever `agents/advisor.md` declares, currently `opus`. `/setup-playbook` changes it permanently.

For `/advisor <model>`, accept `opus`, `sonnet`, `haiku`, `inherit`, or a full model id the user names. Never invent an id. Save the choice in `state.json` and pass it as the `Agent` call's `model` override for this session only. If the `Agent` tool rejects it, say so in one line, fall back to the agent's own model, and do not block the consult.

## Enabling

1. Resolve the model as described above.
2. Write `.claude/playbook/advisor/state.json` with the file-writing tool (not a shell redirect), creating the directory if needed. If a state file already exists, carry over its `model` (unless this command names one) and `nudge`, and reset every other field to the values below. You cannot see which conversation an existing file belongs to, so always rewrite it: that re-binds the mode to this conversation, the hooks re-fill `session_id` and `transcript_path`, and the next consult starts a fresh advisor instead of resuming another chat's. Also delete any `.claude/playbook/advisor/pending-*` marker, so one left by another conversation cannot trigger the end-of-turn nudge here. Keep `log.md`.

   ```json
   {
     "enabled": true,
     "model": "opus",
     "nudge": true,
     "advisor_agent_id": null,
     "session_id": null,
     "transcript_path": null,
     "consults": 0,
     "last_consult_at": null,
     "enabled_at": "<current UTC time, ISO 8601>"
   }
   ```

   The plugin's hooks fill in `session_id`, `transcript_path`, `consults`, and `last_consult_at`. Leave them alone.
3. Confirm in one line: `Advisor on: <slug>. I'll consult it before major decisions, when I'm stuck, and before I call the task done.` Then continue with any task in the same message.

Never stage or commit `.claude/playbook/advisor/`.

## Checkpoints

Consult at these points and nowhere else. Each consult is a strong-model call; the value comes from using it selectively.

1. **Before a major decision.** Choosing between architectures or approaches; changes that are hard to reverse or have a wide blast radius (schema or data migrations, deleting or rewriting a module, public API or config format changes, dependency swaps, auth, payments, or other security-sensitive code); or a request that is ambiguous in a way that would change the work materially. Consult once you have a concrete plan and the options in hand, not before you understand the problem. One consult covers the plan; do not re-consult per file.
2. **When stuck.** The same error or failing test after two genuine fix attempts; behavior you cannot explain from the code; or when you are about to reach for a workaround: a retry loop, a `sleep`, a broad `try/except`, skipping a test, or disabling a check to get past something.
3. **Before declaring done.** Any task that changed logic or touched more than a couple of files: consult once before writing the final summary, and include what you verified and how. Skip for trivial edits (typos, comments, a one-line config change) and say so in one line.
4. **On request.** `/advisor ask ...`, or the user asks what the advisor thinks.

Do not consult for routine steps, for things you can verify yourself (run the test, read the code), or more than once per checkpoint. If you would consult more than about four times in one task, the task should probably be split, or you should ask the user.

## How to consult

1. Read `.claude/playbook/advisor/state.json` and decide which situation you are in:
   - **Mode on here**: the file exists with `enabled: true` and you ran the Enabling steps in this conversation. Checkpoint consults and `/advisor ask` both follow the steps below in full, including the `SendMessage` continuation and state writes.
   - **Not on here**: the file is missing, `enabled` is false, or you did not write it. A file you did not write belongs to another chat; only `/advisor` re-binds it, so leave it alone and never continue an `advisor_agent_id` you did not save yourself. Do not consult at checkpoints. If the user explicitly asks for a consult in this message (`/advisor ask ...`, or a request for a second opinion), run it as a one-off: a fresh spawn on the file's `model` if there is one, otherwise the default; no continuation, no state writes, and no `transcript_path` (another chat's transcript is not yours to share; write "not available"). Mention that `/advisor` turns the mode on for this conversation.
2. Build the briefing from `references/briefing-template.md`. Give the advisor everything it needs to disagree with you:
   - The user's request verbatim, plus constraints or corrections they added later.
   - What has happened so far, in order: what you investigated, decided, changed, tried, and ruled out.
   - Relevant tool results verbatim: error messages, stack traces, test output, diffs. Trim unrelated noise and mark trims with `[...]`, but never paraphrase evidence.
   - Current state: `git status --short`, `git diff --stat`, files you touched, anything half-done.
   - Your specific questions, the options you see, and your current leaning with reasons.
   - The `transcript_path` from `state.json` when set and the mode is on in this conversation, so the advisor can read the full conversation itself.
   - No secrets. Redact tokens, keys, and `.env` values.
3. Spawn the advisor and wait for its result before continuing:
   - `Agent` with `subagent_type: "advisor"`
   - `model: <state.model>` only when it differs from the agent's own
   - `description: "Advisor: <checkpoint>"`, for example `Advisor: pre-completion review`
   - When `state.advisor_agent_id` is set, continue that advisor with `SendMessage` instead of a fresh `Agent` call. It keeps the context of earlier consults, so the briefing can be a delta: what changed since last time plus the new questions. If the send fails, spawn fresh.
   - Save the returned agent id or name to `advisor_agent_id` in `state.json`. Clear it when the model changes.
4. Act on the verdict:
   - `proceed`: go.
   - `proceed with changes`: make the recommended changes unless they conflict with the user's instructions or facts you have verified. Say which you skipped and why.
   - `stop`: do not continue with the plan. Rethink, or bring the disagreement to the user if it is a product or scope question.
   - If the advisor asks for something it needs, provide it with one `SendMessage`. Do not ping-pong.
   - You are accountable for the result. The advisor is a strong second opinion, not an authority. If it is wrong about the codebase, show it the evidence once, or overrule it and tell the user why.
5. Report each consult to the user in one or two lines: `Advisor (<model>): <verdict>. <One-line summary>. <What you did about it.>` Keep the advisor's full response out of the chat unless the user asks; the `SubagentStop` hook also appends it to `.claude/playbook/advisor/log.md`.

## End-of-turn nudge

When files changed since the last consult and a turn ends without one, the plugin's `Stop` hook injects a note that starts with `[Advisor]`. Treat it as the "before declaring done" checkpoint: run the pre-completion consult, or answer in one line that the change was trivial, or that you are waiting on the user, and stop. It fires at most once per batch of edits. `/advisor nudge off` disables it.

## Disabling

`/advisor off`: delete `.claude/playbook/advisor/` and confirm in one line. Do not consult again in this conversation unless the user re-enables the mode or explicitly asks for a one-off consult.

## Guardrails

- Never enable advisor mode unasked. "Get a second opinion on this" is a one-off consult, not a mode change.
- The advisor is read-only. Never ask it to edit files or do the task.
- Never loop on the advisor: at most one follow-up per checkpoint.
- If the `advisor` agent is unavailable (no `Agent` tool, or a hook denies it), tell the user once and continue without it.
