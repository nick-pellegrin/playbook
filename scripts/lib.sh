#!/usr/bin/env bash

# Shared helpers for the playbook hooks. Source this file; do not run it.
#
# State lives in $CLAUDE_PROJECT_DIR/.claude/playbook/advisor/:
#   state.json            written by the advisor skill, kept current here
#   pending-<session_id>   marker: files were edited since the last consult
#   log.md                one entry per completed consult

PLAYBOOK_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/playbook"
ADVISOR_DIR="$PLAYBOOK_DIR/advisor"
STATE_FILE="$ADVISOR_DIR/state.json"
LOG_FILE="$ADVISOR_DIR/log.md"

# Exit quietly unless advisor mode is on and jq is available.
advisor_require_enabled() {
  command -v jq >/dev/null 2>&1 || exit 0
  [[ -f "$STATE_FILE" ]] || exit 0
  [[ "$(jq -r '.enabled // false' "$STATE_FILE" 2>/dev/null)" == "true" ]] || exit 0
}

# Atomically apply a jq filter to state.json.
# Usage: advisor_state_update '<filter>' [jq args...]
advisor_state_update() {
  local filter="$1"
  shift
  local tmp="${STATE_FILE}.tmp.$$"
  if jq "$@" "$filter" "$STATE_FILE" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$STATE_FILE"
  else
    rm -f "$tmp"
  fi
}

# Bind the state to the first session that touches it and keep transcript_path
# current. Returns 1 when the hook input belongs to a different session, so
# callers stay out of sessions that did not enable the advisor. A fresh bind
# drops per-session markers so a re-bind cannot inherit the previous session's
# pending edits.
advisor_bind_session() {
  local input="$1"
  local sid bound transcript current
  sid=$(jq -r '.session_id // empty' <<< "$input")
  bound=$(jq -r '.session_id // empty' "$STATE_FILE")
  if [[ -n "$sid" ]]; then
    if [[ -z "$bound" ]]; then
      advisor_state_update '.session_id = $sid' --arg sid "$sid"
      rm -f "$ADVISOR_DIR"/pending-*
    elif [[ "$bound" != "$sid" ]]; then
      return 1
    fi
  fi
  PENDING_FILE="$ADVISOR_DIR/pending-${sid:-unbound}"
  transcript=$(jq -r '.transcript_path // empty' <<< "$input")
  current=$(jq -r '.transcript_path // empty' "$STATE_FILE")
  if [[ -n "$transcript" && "$transcript" != "$current" ]]; then
    advisor_state_update '.transcript_path = $path' --arg path "$transcript"
  fi
  return 0
}
