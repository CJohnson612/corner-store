#!/bin/bash
# Stop hook — fires at the end of each Claude turn.
# Reads the file queue built by the PostToolUse hook, clears it, then triggers
# rules-maintainer if any relevant source files were edited this turn.
# Clearing before blocking breaks the infinite-loop: the next Stop invocation
# finds an empty queue and exits silently.

DEBUG_LOG="/tmp/hier-rules-debug.log"
echo "[trigger $(date '+%H:%M:%S')] script fired — CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}" >> "$DEBUG_LOG"

QUEUE_FILE="/tmp/rules-maintainer-queue.txt"

if [ ! -s "$QUEUE_FILE" ]; then
  echo "[trigger $(date '+%H:%M:%S')] queue empty, exiting" >> "$DEBUG_LOG"
  exit 0
fi

changed_files=$(sort -u "$QUEUE_FILE")
rm -f "$QUEUE_FILE"
echo "[trigger $(date '+%H:%M:%S')] queued files: $changed_files" >> "$DEBUG_LOG"

if [ -n "$changed_files" ]; then
  reason="Use the Skill tool to invoke the hier-rules:rules-maintainer skill before stopping. Do not respond to the user — run the skill immediately.

Files edited this turn:
$changed_files"
  python3 -c "
import json, sys
reason = sys.argv[1]
print(json.dumps({'decision': 'block', 'reason': reason}))
" "$reason"
fi
