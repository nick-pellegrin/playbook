#!/usr/bin/env bash

# SubagentStop hook for Advisor (matcher: advisor).
# Counts the consult, clears the pending-edits marker, and appends the advice to
# .claude/playbook/advisor/log.md so the user can review it later.
#
# Input:  { "agent_type": "advisor", "agent_transcript_path": "...", ...common }
# Output: none

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

HOOK_INPUT=$(cat)

advisor_require_enabled
advisor_bind_session "$HOOK_INPUT" || exit 0

AGENT_TYPE=$(jq -r '.agent_type // .subagent_type // empty' <<< "$HOOK_INPUT")
if [[ "$AGENT_TYPE" != "advisor" ]]; then
  exit 0
fi

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
advisor_state_update '.consults = ((.consults // 0) + 1) | .last_consult_at = $now' --arg now "$NOW"
rm -f "$PENDING_FILE"

DESCRIPTION=$(jq -r '.description // "Advisor consult"' <<< "$HOOK_INPUT")

# The verdict is the last assistant message in the advisor's own transcript.
SUMMARY=""
AGENT_TRANSCRIPT=$(jq -r '.agent_transcript_path // empty' <<< "$HOOK_INPUT")
if [[ -n "$AGENT_TRANSCRIPT" && -f "$AGENT_TRANSCRIPT" ]]; then
  SUMMARY=$(jq -rs '
    [ .[]
      | select(.type == "assistant")
      | .message.content
      | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end
    ] | last // empty
  ' "$AGENT_TRANSCRIPT" 2>/dev/null | head -c 6000) || SUMMARY=""
fi

mkdir -p "$ADVISOR_DIR"
{
  printf '## %s — %s\n\n' "$NOW" "$DESCRIPTION"
  if [[ -n "$SUMMARY" ]]; then
    printf '%s\n\n' "$SUMMARY"
  else
    printf '_No summary captured._\n\n'
  fi
} >> "$LOG_FILE"

exit 0
