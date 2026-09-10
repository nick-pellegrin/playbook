---
name: interrogate
description: "Use for \"interrogate\", \"adversarial review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". Three reviewers challenge the same diff through three different rubrics."
disable-model-invocation: true
---

# Interrogate

Spawn three reviewers to adversarially review one change. Each gets the same diff and the same stated intent, and each applies a different rubric. The adversarial signal comes from lens diversity: three rubrics disagreeing about one diff is information, three copies of one rubric is not.

The deliverable is a synthesized verdict. Do NOT auto-apply changes.

## Step 1, Determine Scope

Identify what to review from context:

- If the user points at specific files or a diff, use that
- If on a feature branch, run `git diff main...HEAD` (or the appropriate base branch) for the full changeset
- If the user's message references recent work, gather the relevant files

Package the diff (or file contents) plus any surrounding context files the reviewers need to understand the code.

## Step 2, State the Intent

Before spawning reviewers, state the intent explicitly. Derive this from:

- The user's message
- Commit messages
- PR description if one exists
- The code itself

Write one clear paragraph. If you're unsure about the intent, ask the user before proceeding.

## Step 3, Spawn Reviewers

Launch all three reviewers in a single message, one `Agent` call each. All three are read-only by their frontmatter, so none of them can edit the code under review.

| Reviewer | `subagent_type` | Lens |
|---|---|---|
| Reviewer A | `reviewer` | The interrogate rubric. `references/rubric.md` plus `references/code-quality-review.md`. |
| Reviewer B | `reviewer-bugs` | Bugs, breakage, security, devex regressions, feature-gate leaks. |
| Reviewer C | `reviewer-quality` | Maintainability, structure, file sprawl, spaghetti conditions, code-judo moves. |

Reviewer A gets `references/reviewer-prompt.md` filled in with:
1. The stated intent
2. The diff or file contents
3. The review rubric from `references/rubric.md`
4. The code-quality lens from `references/code-quality-review.md`

Reviewers B and C get the stated intent, the diff under `### Git / diff output`, and the changed-file contents under `### Changed file contents`. They load their own rubrics from the `review-lens-bugs` and `review-lens-quality` skills.

Add a fourth reviewer only for a genuinely different lens (a domain expert prompt, a performance rubric). Running the same lens twice buys nothing.

**Restoring true model diversity.** With one vendor, agreement between lenses is weaker evidence than agreement between vendors was. When a second vendor's coding CLI is installed and authenticated, add it as Reviewer D:

```bash
git diff <base>...HEAD | scripts/external-review.sh "<the stated intent from Step 2>"
```

It reads the CLI invocation from `PLAYBOOK_EXTERNAL_REVIEW_CMD` and exits 3 when that is unset, which means "no second vendor configured", not a failure. Fold its findings in as a fourth reviewer. That is the only way to keep "a second opinion is the same prompt on a different model" honest.

## Step 4, Synthesize

As results come back, build a unified picture:

1. **Parse all findings** from the reviewers
2. **Identify consensus**. Findings raised by 2+ reviewers independently are highest signal, and a finding two *different lenses* reached is stronger still.
3. **Identify lone-reviewer findings**. Still worth reading, but weight accordingly. A finding only the lens that specializes in it raised is not automatically weak.
4. **Deduplicate**. Different lenses may describe the same issue differently. Merge these and note which reviewers raised it.
5. **Note disagreements**. If one reviewer flags something and another explicitly says the opposite, that's useful context for the verdict.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator.

Read `references/lead-judgment.md` for the full framework.

Categorize every finding using these buckets:

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. These would block a real PR.
- **Consider**. Legitimate points, but you're not sure they outweigh the cost of addressing them right now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact given the current stage.
- **Dismissed**. Wrong, nitpicky, or missing context. Brief explanation why.

For each finding, include:
- Which reviewer(s) raised it
- The category (act on / consider / noted / dismissed)
- A one-line rationale for the categorization

## Output Format

Present the verdict in this structure:

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: [lens], [N findings] (one bullet per reviewer)

### Act On
[Findings that should be addressed. For each: description, which reviewers raised it, why it matters.]

### Consider
[Findings worth thinking about. For each: description, which reviewers raised it, tradeoff involved.]

### Noted
[Valid but low-priority. Brief list.]

### Dismissed
[Rejected findings with brief rationale.]

### Agreement Map
[Where did the lenses agree, where did they diverge, and what does the pattern of agreement/disagreement tell us?]
