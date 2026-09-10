# Changelog

## 0.1.0

First release. A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) v0.15.1 (MIT, Lauren Tan) from Cursor to Claude Code, plus a curated subset of `cursor-team-kit`, `thermos`, `advisor`, `continual-learning`, and `cli-for-agent` vendored into one plugin.

### Renamed

- `poteto-mode` is now the `playbook` skill, entered with `/playbook`.
- `poteto-agent` is now `playbook-agent`. `setup-pstack` is now `setup-playbook`.
- `references/bugbot-triage.md` is now `references/review-bot-triage.md`, generalized to any PR review bot.
- The two thermos rubrics are now `review-lens-bugs` and `review-lens-quality`, loaded by the `reviewer-bugs` and `reviewer-quality` agents.

### Translated to Claude Code

- `Task` calls become `Agent` calls. `run_in_background` and `readonly` move into agent frontmatter as `background` and `disallowedTools`. Worktree-scoped workers use `isolation: worktree`.
- `AskQuestion` becomes `AskUserQuestion`.
- Cursor's `/loop` becomes the `loop` skill, with the Ralph Wiggum plugin named for runs that must survive the turn ending.
- Cursor hook events become their PascalCase equivalents: `afterFileEdit` to `PostToolUse`, `afterAgentResponse` and `stop` to `Stop`, `subagentStop` to `SubagentStop`. Every Stop hook checks `stop_hook_active` first. Nudges are emitted as `hookSpecificOutput.additionalContext`.
- The advisor's `capture-response.sh` is gone. `Stop` supplies `last_assistant_message` directly.
- `continual-learning-stop.ts` is ported to bash and jq, so the hooks need no Bun.
- Transcript paths move from `~/.cursor/projects/<slug>/agent-transcripts/` to `~/.claude/projects/<slug>/*.jsonl`.
- Continual learning writes `CLAUDE.md` instead of `AGENTS.md`.
- Per-repo state moves to `.claude/playbook/`.
- Cursor's `create-skill` becomes `skill-creator`.
- The stacked-PR CLI paths collapse to `gh`.
- `watch-pr`'s review-bot detection is vendor-neutral and matches Claude Code Review, CodeRabbit, Copilot, and others alongside Bugbot.

### Model routing

- The `~/.cursor/rules/pstack-models.mdc` always-applied rule is gone. Model choice lives in `agents/*.md` frontmatter, edited in place by `/setup-playbook`. No literal model id appears in any `SKILL.md`.
- New role agents: `code-worker`, `judgment-worker`, `reviewer`, `explorer`.
- `interrogate` and `arena` lose cross-vendor panels and use lens diversity instead: one diff, three rubrics. The `thermos` orchestrator skill is retired into `interrogate`.

### Dropped

- `make-bot-ui`. Cursor routines and webhooks, with no Claude Code equivalent.
- `automations/benny/`, `docs/guide/`, `assets/logo.png`.
