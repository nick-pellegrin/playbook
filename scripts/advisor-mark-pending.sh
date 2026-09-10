#!/usr/bin/env bash

# PostToolUse hook for Advisor (matcher: Write|Edit|MultiEdit|NotebookEdit).
# Remembers that files changed since the last advisor consult, so the Stop hook
# can ask for a pre-completion review if the turn ends without one.
#
# Input:  { "tool_name": "...", "tool_input": { "file_path": "..." }, ...common }
# Output: none

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

HOOK_INPUT=$(cat)

advisor_require_enabled
advisor_bind_session "$HOOK_INPUT" || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<< "$HOOK_INPUT")

# The plugin's own state is not work product.
case "$FILE_PATH" in
  */.claude/playbook/*) exit 0 ;;
esac

touch "$PENDING_FILE"
exit 0
