#!/usr/bin/env bash

# Optional second-vendor reviewer for the interrogate skill.
#
# Lens diversity (three rubrics, one vendor) is interrogate's default. This
# script restores true model diversity when another vendor's coding CLI is
# installed and authenticated: it pipes a diff to that CLI with the interrogate
# rubric and prints the findings on stdout.
#
# Usage:  git diff main...HEAD | PLAYBOOK_EXTERNAL_REVIEW_CMD="<cli> -p" scripts/external-review.sh "<stated intent>"
#
# PLAYBOOK_EXTERNAL_REVIEW_CMD is the CLI invocation that reads a prompt on
# stdin and prints its answer on stdout. Set it once in your shell profile.
# Examples: "codex exec", "gemini -p", "llm -m <model>".
#
# Exits 3 when no CLI is configured, so interrogate can fall back to three
# lenses without treating it as a failure.

set -euo pipefail

INTENT="${1:-}"
CMD="${PLAYBOOK_EXTERNAL_REVIEW_CMD:-}"

if [[ -z "$CMD" ]]; then
  echo "external-review: PLAYBOOK_EXTERNAL_REVIEW_CMD is not set; skipping the second-vendor lens." >&2
  exit 3
fi

DIFF=$(cat)
if [[ -z "${DIFF//[[:space:]]/}" ]]; then
  echo "external-review: empty diff on stdin." >&2
  exit 2
fi

PROMPT=$(cat <<PROMPT_END
You are an adversarial code reviewer. Review only the change below. Do not edit anything.

Stated intent of the change:
$INTENT

Rules:
- Report only what the diff shows. Report a pre-existing problem only when the diff makes it load-bearing.
- Every finding carries file:line and the concrete failure it causes.
- Calibrate severity honestly. Do not pad with nits.
- Order findings most-severe first. Say plainly when you found nothing.

Diff:
$DIFF
PROMPT_END
)

printf '%s' "$PROMPT" | eval "$CMD"
