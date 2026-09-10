#!/usr/bin/env bash

# Stop hook for continual learning.
# Throttled by turns and elapsed minutes, so the memory pass stays cheap. When
# both thresholds are met and the transcript has actually advanced, ask the
# agent to run the continual-learning skill.
#
# Input:  { "session_id": "...", "transcript_path": "...", "stop_hook_active": bool }
# Output: {"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"..."}}
#
# Tunables (env): CONTINUAL_LEARNING_MIN_TURNS (10), CONTINUAL_LEARNING_MIN_MINUTES (120),
#                 CONTINUAL_LEARNING_OFF (set to 1 to disable).

set -euo pipefail

if [[ "${CONTINUAL_LEARNING_OFF:-}" == "1" ]]; then
  exit 0
fi
command -v jq >/dev/null 2>&1 || exit 0

HOOK_INPUT=$(cat)
if [[ "$(jq -r '.stop_hook_active // false' <<< "$HOOK_INPUT")" == "true" ]]; then
  exit 0
fi

PLAYBOOK_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/playbook"
STATE_PATH="$PLAYBOOK_DIR/continual-learning.json"
INDEX_PATH="$PLAYBOOK_DIR/continual-learning-index.json"
mkdir -p "$PLAYBOOK_DIR"

MIN_TURNS="${CONTINUAL_LEARNING_MIN_TURNS:-10}"
MIN_MINUTES="${CONTINUAL_LEARNING_MIN_MINUTES:-120}"

NOW_MS=$(( $(date +%s) * 1000 ))
TRANSCRIPT=$(jq -r '.transcript_path // empty' <<< "$HOOK_INPUT")

TRANSCRIPT_MTIME_MS=0
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  TRANSCRIPT_MTIME_MS=$(( $(date -r "$TRANSCRIPT" +%s) * 1000 ))
fi

if [[ -f "$STATE_PATH" ]]; then
  LAST_RUN_MS=$(jq -r '.lastRunAtMs // 0' "$STATE_PATH")
  TURNS=$(jq -r '.turnsSinceLastRun // 0' "$STATE_PATH")
  LAST_MTIME_MS=$(jq -r '.lastTranscriptMtimeMs // 0' "$STATE_PATH")
else
  LAST_RUN_MS=0; TURNS=0; LAST_MTIME_MS=0
fi

TURNS=$(( TURNS + 1 ))

if [[ "$LAST_RUN_MS" -gt 0 ]]; then
  MINUTES=$(( (NOW_MS - LAST_RUN_MS) / 60000 ))
else
  MINUTES=$(( MIN_MINUTES + 1 ))
fi

write_state() {
  jq -n --argjson run "$1" --argjson turns "$2" --argjson mtime "$3" \
    '{version: 1, lastRunAtMs: $run, turnsSinceLastRun: $turns, lastTranscriptMtimeMs: $mtime}' \
    > "$STATE_PATH"
}

if [[ "$TURNS" -lt "$MIN_TURNS" || "$MINUTES" -lt "$MIN_MINUTES" || "$TRANSCRIPT_MTIME_MS" -le "$LAST_MTIME_MS" ]]; then
  write_state "$LAST_RUN_MS" "$TURNS" "$LAST_MTIME_MS"
  exit 0
fi

write_state "$NOW_MS" 0 "$TRANSCRIPT_MTIME_MS"

MESSAGE="Run the \`continual-learning\` skill now. Use the \`memory-updater\` agent for the full memory update flow. Use incremental transcript processing with index file \`$INDEX_PATH\`: only consider transcripts not in the index or transcripts whose mtime is newer than the indexed mtime. Have the agent refresh index mtimes, remove entries for deleted transcripts, and update \`CLAUDE.md\` only for high-signal recurring user corrections and durable workspace facts. Exclude one-off or transient details and secrets. If no meaningful updates exist, respond exactly: No high-signal memory updates."

jq -n --arg msg "$MESSAGE" '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $msg}}'
exit 0
