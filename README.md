# playbook

A Claude Code plugin that routes a task to a matching playbook, then works it with named principles, deliberate subagents, and evidence for every claim.

Start a task with `/playbook`. It reads the request, picks one of twenty-three playbooks, copies that playbook's steps into the todo list verbatim, and pulls in the other skills as the steps need them. The point is not to write more code. It is to write less of it and prove the part that ships.

Forked from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT), with the Cursor-specific mechanisms replaced by their Claude Code equivalents, and with a curated subset of `cursor-team-kit`, `thermos`, `advisor`, `continual-learning`, and `cli-for-agent` vendored in.

## Install

The plugin is a plain directory. Two ways to load it.

**As a skills-directory plugin (recommended while you are still editing it).** Symlink or copy the tree into your user skills directory. Edits to a `SKILL.md` take effect live, with no marketplace step.

```bash
# macOS / Linux
ln -s "$PWD/playbook" ~/.claude/skills/playbook
```

```powershell
# Windows, from an elevated prompt
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills\playbook" -Target "$PWD\playbook"
```

**As an installed plugin.** This directory is its own single-plugin marketplace (`.claude-plugin/marketplace.json`), so it installs straight from a path or a repo.

```bash
claude plugin marketplace add ./playbook      # or <owner>/<repo> once it is pushed
claude plugin install playbook@playbook
```

Either way, verify both manifests before using it:

```bash
claude plugin validate ./playbook/.claude-plugin/plugin.json --strict
claude plugin validate ./playbook/.claude-plugin/marketplace.json --strict
```

Then in a session, `/reload-plugins` picks up any edit.

### Optional pieces

- **Hooks.** `hooks/hooks.json` wires the advisor nudge and the continual-learning throttle. They need `jq` on `PATH` and executable bits on `scripts/*.sh`. Both stay silent unless you turn them on: the advisor hook only fires when `/advisor` wrote a state file, and continual-learning only fires after its turn and time thresholds pass. `CONTINUAL_LEARNING_OFF=1` disables the latter outright.
- **`watch-pr` and `orch`.** TypeScript tools under `skills/playbook/scripts/`, run with [Bun](https://bun.sh). `bun install --frozen-lockfile` in that directory installs them. The Babysit and Shipping playbooks call `watch-pr` for PR status. Without Bun, both playbooks still work through plain `gh` commands, just without the polled verdict. Two `orch` tests fail on Windows because their fake `gt` shim is a shell script the OS will not exec. They fail the same way upstream and do not affect `watch-pr`.
- **A loop.** The Autonomous run and Autopilot playbooks pace themselves with the `/loop` skill. For a run that must survive the turn ending, install the Ralph Wiggum plugin and let its Stop hook restart you against the predicate.

## Get started

1. `/setup-playbook` and pick a model per role. Defaults are Sonnet for mechanical code, Opus for judgment and review.
2. `/playbook <your task>` whenever the work needs rigor.

To make the mode sticky for a whole session, add one line to your `CLAUDE.md`:

> When playbook mode is on, apply the `playbook` skill to every nontrivial turn.

## How it fits together

```
/playbook
  ├─ matches a playbook          → copies its steps into the todo list verbatim
  ├─ cites principles it applied → each one read from its own leaf skill first
  ├─ delegates through roles     → code-worker / judgment-worker / reviewer / explorer
  └─ writes the reply per unslop → every claim labeled measured, inferred, or guess
```

The single rule that carries the most weight: **cite only principles whose leaf `SKILL.md` you actually read this session.** It is what keeps the principle index from degrading into decoration.

## The twenty-three playbooks

Each lives in `skills/playbook/playbooks/`.

| Playbook | For |
|---|---|
| [investigation](./skills/playbook/playbooks/investigation.md) | A read-only question. How does X work, why was Y built this way, are we sure about Z. |
| [bug-fix](./skills/playbook/playbooks/bug-fix.md) | Reproduce a defect, root-cause it, fix it with runtime evidence. |
| [perf-issue](./skills/playbook/playbooks/perf-issue.md) | Trace a measured slowness and improve it against a baseline. |
| [hillclimb](./skills/playbook/playbooks/hillclimb.md) | Sustained improvement of one metric against a target, one commit per accepted win. |
| [runtime-forensics](./skills/playbook/playbooks/runtime-forensics.md) | Diagnose a live symptom (leak, idle-CPU spin, glitch) from instrumentation. |
| [trace-forensics](./skills/playbook/playbooks/trace-forensics.md) | Diagnose a captured profiling artifact handed to you after the fact. |
| [feature](./skills/playbook/playbooks/feature.md) | New or changed behavior, built from a named data shape. |
| [refactoring](./skills/playbook/playbooks/refactoring.md) | A behavior-preserving change to structure or shape. |
| [prototype](./skills/playbook/playbooks/prototype.md) | A throwaway sketch that settles a design fork by observation instead of by asking. |
| [visual-parity](./skills/playbook/playbooks/visual-parity.md) | Pixel-exact UI equivalence between two implementations. |
| [authoring-a-skill](./skills/playbook/playbooks/authoring-a-skill.md) | Writing or editing a `SKILL.md`. |
| [eval](./skills/playbook/playbooks/eval.md) | Blinded A/B of a skill, structure, or prompt change before promoting it. |
| [babysit](./skills/playbook/playbooks/babysit.md) | Driving a PR or a stack to merge-ready: conflicts, review threads, CI. |
| [shipping](./skills/playbook/playbooks/shipping.md) | The half after babysit. Independently verify a green stack, then land it bottom-up. |
| [autonomous-run](./skills/playbook/playbooks/autonomous-run.md) | One long task driven to a checkable predicate without stopping. |
| [orchestrate](./skills/playbook/playbooks/orchestrate.md) | A standing multi-day program under one coordinator. |
| [autopilot-full](./skills/playbook/playbooks/autopilot-full.md) | A queue of independent PRs run to merged, one owner per PR. |
| [autopilot-stack](./skills/playbook/playbooks/autopilot-stack.md) | The same queue, delivered as one linear stack the operator lands herself. |
| [session-pickup](./skills/playbook/playbooks/session-pickup.md) | Resuming a prior agent's in-flight work from a transcript, URL, or branch. |
| [pause-safely](./skills/playbook/playbooks/pause-safely.md) | Suspending in-flight work cleanly so it can be resumed. |
| [multi-phase-plan](./skills/playbook/playbooks/multi-phase-plan.md) | Work spanning phases or stacked PRs. |
| [worktree-cleanup](./skills/playbook/playbooks/worktree-cleanup.md) | Reclaiming disk from merged worktrees and stale simulators. |
| [opening-a-pr](./skills/playbook/playbooks/opening-a-pr.md) | Invoked at the end of every other playbook. |

## Skills

**Principles** (23 leaves under `skills/principle-*/`). Read in full before you cite one.

*Core:* laziness-protocol, foundational-thinking, redesign-from-first-principles, attack-the-premise, subtract-before-you-add, minimize-reader-load, outcome-oriented-execution, experience-first, exhaust-the-design-space, build-the-lever.

*Architecture:* model-the-domain, boundary-discipline, type-system-discipline, make-operations-idempotent, migrate-callers-then-delete-legacy-apis, separate-before-serializing-shared-state.

*Verification:* prove-it-works, fix-root-causes, sequence-verifiable-units, test-behavior-not-implementation.

*Delegation:* guard-the-context-window, never-block-on-the-human.

*Meta:* encode-lessons-in-structure.

**Workflows.**

| Skill | For |
|---|---|
| [how](./skills/how/SKILL.md) | How does X work. Walkthroughs, placement, ownership, layering. |
| [why](./skills/why/SKILL.md) | Design rationale, regressions, postmortems, data-backed thresholds. |
| [architect](./skills/architect/SKILL.md) | Types, signatures, and module structure sketched before code. |
| [arena](./skills/arena/SKILL.md) | N parallel candidates at one task, pick a base, graft the winners' parts. |
| [swarm](./skills/swarm/SKILL.md) | Parallel coverage matrices, races, gauntlets, exploration partitions. |
| [interrogate](./skills/interrogate/SKILL.md) | Three reviewers, one diff, three rubrics. Adversarial review before shipping. |
| [reflect](./skills/reflect/SKILL.md) | Three lenses over the session transcript, routed to concrete skill edits. |
| [figure-it-out](./skills/figure-it-out/SKILL.md) | Design a bespoke playbook when no bundled one fits. |
| [blast-radius](./skills/blast-radius/SKILL.md) | What this change could break outside the diff, proven by running code. |
| [teach](./skills/teach/SKILL.md) | Explain a body of work plainly to a person. |
| [recall](./skills/recall/SKILL.md) | Rebuild working context from chat history, live state, and the shared record. |
| [advisor](./skills/advisor/SKILL.md) | Consult a second opinion at checkpoints. Off by default. |
| [continual-learning](./skills/continual-learning/SKILL.md) | Mine transcripts into durable `CLAUDE.md` facts. |
| [automate-me](./skills/automate-me/SKILL.md) | Turn how you actually work into your own `-mode` skill. |
| [show-me-your-work](./skills/show-me-your-work/SKILL.md) | A reviewable TSV decision trail for unattended work. |
| [verify-this](./skills/verify-this/SKILL.md) | Restate a claim falsifiably, capture baseline and treatment, return a verdict. |

**Writing and code hygiene.** [unslop](./skills/unslop/SKILL.md), [technical-writing](./skills/technical-writing/SKILL.md), [deslop](./skills/deslop/SKILL.md), [no-comments](./skills/no-comments/SKILL.md), [tdd](./skills/tdd/SKILL.md), [typescript-best-practices](./skills/typescript-best-practices/SKILL.md), [cli-for-agents](./skills/cli-for-agents/SKILL.md), [bro](./skills/bro/SKILL.md).

**Driving the real thing.** [control-cli](./skills/control-cli/SKILL.md), [control-ui](./skills/control-ui/SKILL.md), [create-verification-skill](./skills/create-verification-skill/SKILL.md), [maintain-verification-skill](./skills/maintain-verification-skill/SKILL.md), [run-smoke-tests](./skills/run-smoke-tests/SKILL.md).

**PR plumbing.** [fix-ci](./skills/fix-ci/SKILL.md), [loop-on-ci](./skills/loop-on-ci/SKILL.md), [fix-merge-conflicts](./skills/fix-merge-conflicts/SKILL.md), [get-pr-comments](./skills/get-pr-comments/SKILL.md), [make-pr-easy-to-review](./skills/make-pr-easy-to-review/SKILL.md), [new-branch-and-pr](./skills/new-branch-and-pr/SKILL.md), [check-compiler-errors](./skills/check-compiler-errors/SKILL.md), [what-did-i-get-done](./skills/what-did-i-get-done/SKILL.md).

**Review rubrics.** [review-lens-bugs](./skills/review-lens-bugs/SKILL.md) and [review-lens-quality](./skills/review-lens-quality/SKILL.md) are the rubrics `interrogate`'s second and third reviewers load. They also stand alone for a single deep audit.

## Agents

Model routing lives in agent frontmatter, one file per role. `/setup-playbook` edits it in place.

| Agent | Model | Role |
|---|---|---|
| `playbook-agent` | inherit | Any in-playbook delegate that needs the principles read. |
| `code-worker` | sonnet | Mechanical edits, sweeps, codemods, fully specified steps. |
| `judgment-worker` | opus | Cross-cutting design, concurrency, subtle algorithms. |
| `reviewer` | opus | Read-only adversarial review. Cannot write. |
| `reviewer-bugs` | opus | Read-only, bugs and security lens. |
| `reviewer-quality` | opus | Read-only, maintainability lens. |
| `explorer` | sonnet | Read-only recon. Returns file pointers, not file contents. |
| `advisor` | opus | Second opinion at checkpoints. Read-only. |
| `ci-watcher` | sonnet | Watch PR checks and report. |
| `comment-sicko` | sonnet | Deletes comments, flags refactor targets, writes no application code. |
| `memory-updater` | inherit | Mines transcripts into `CLAUDE.md`. |

## Review diversity

pstack got its adversarial signal from running the same prompt on four vendors' models. On one vendor that is not available, so `interrogate` and `arena` use **lens diversity** instead: the same diff goes to three reviewers with three different rubrics, and agreement between two *different* lenses is the high-signal case. If you have a second vendor's coding CLI installed, `interrogate` documents the escape hatch: pipe the diff through `scripts/external-review.sh` with `PLAYBOOK_EXTERNAL_REVIEW_CMD` set, and fold its findings in as a fourth reviewer.

## What was left behind

Not ported from pstack, deliberately: `orchestrate`'s Cursor SDK bindings, `make-bot-ui` (Cursor routines and webhooks, no equivalent), the `benny` GitHub Actions automation, the `docs/guide/` walkthrough, and the `ralph-loop` plugin (Claude Code has its own).

## License

MIT. See [LICENSE](./LICENSE).
