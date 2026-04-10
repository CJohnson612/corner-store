#!/bin/bash
# PostToolUse hook — fires after Write, Edit, or Bash tool calls.
# - Write/Edit: queues the file_path if it matches a watched rules pattern.
# - Bash: checks for rm commands, extracts paths, queues matches.
# This script is codebase-agnostic: watched paths come from .claude/rules/**/*.md frontmatter.

DEBUG_LOG="/tmp/hier-rules-debug.log"
exec 2>> "$DEBUG_LOG"  # redirect all stderr to the debug log

echo "=== [queue $(date '+%Y-%m-%d %H:%M:%S')] SCRIPT FIRED ===" >> "$DEBUG_LOG"
echo "[queue] CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}" >> "$DEBUG_LOG"
echo "[queue] PWD=${PWD}" >> "$DEBUG_LOG"
echo "[queue] USER=${USER:-unknown}" >> "$DEBUG_LOG"

QUEUE_FILE="/tmp/rules-maintainer-queue.txt"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
echo "[queue] REPO_ROOT=${REPO_ROOT}" >> "$DEBUG_LOG"

if [ -z "$REPO_ROOT" ]; then
  echo "[queue] ERROR: no git repo found, exiting" >> "$DEBUG_LOG"
  exit 0
fi

# Save stdin to a temp file — avoids the pipe+heredoc stdin conflict
STDIN_TMP=$(mktemp)
cat > "$STDIN_TMP"
echo "[queue] stdin: $(cat "$STDIN_TMP")" >> "$DEBUG_LOG"

echo "[queue] running python3..." >> "$DEBUG_LOG"
python3 - "$REPO_ROOT" "$QUEUE_FILE" "$STDIN_TMP" << 'PYEOF'
import sys, os, re, glob, json

repo_root  = sys.argv[1]
queue_file = sys.argv[2]
stdin_file = sys.argv[3]

try:
    with open(stdin_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

tool_name = data.get('tool_name', '')

def get_candidate_paths(data, tool_name):
    if tool_name in ('Write', 'Edit'):
        path = data.get('tool_input', {}).get('file_path', '')
        return [path] if path else []

    if tool_name == 'Bash':
        command = data.get('tool_input', {}).get('command', '')
        if not re.search(r'\brm\b', command):
            return []
        paths = []
        paths.extend(re.findall(r'"([^"]+)"', command))
        paths.extend(re.findall(r"'([^']+)'", command))
        stripped = re.sub(r'"[^"]*"', '', command)
        stripped = re.sub(r"'[^']*'", '', stripped)
        for token in stripped.split():
            if token not in ('rm',) and not token.startswith('-'):
                if '/' in token or '\\' in token or ('.' in token and not token.startswith('.')):
                    paths.append(token)
        return paths

    return []

candidate_paths = get_candidate_paths(data, tool_name)
if not candidate_paths:
    sys.exit(0)

def matches_pattern(path, pattern):
    pattern = pattern.replace('\\', '/')
    p = re.escape(pattern)
    p = p.replace(r'\*\*/', '(?:.+/)?')
    p = p.replace(r'\*\*', '.+')
    p = p.replace(r'\*', '[^/]+')
    p = p.replace(r'\?', '[^/]')
    return bool(re.match('^(?:.+/)?' + p + '$', path))

rules_files = glob.glob(os.path.join(repo_root, '.claude/rules/**/*.md'), recursive=True)
watched_patterns = []

for rules_file in rules_files:
    try:
        with open(rules_file, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        continue
    if not content.startswith('---'):
        continue
    end = content.find('---', 3)
    if end < 0:
        continue
    frontmatter = content[3:end]
    m = re.search(r'^paths:\s*\n((?:[ \t]+-[ \t]+\S.*\n?)+)', frontmatter, re.MULTILINE)
    if m:
        for line in m.group(1).splitlines():
            pattern = re.sub(r'^[ \t]+-[ \t]+', '', line).strip().strip("'\"")
            if pattern:
                watched_patterns.append(pattern)

for raw_path in candidate_paths:
    file_path = raw_path.replace('\\', '/')
    if os.path.isabs(file_path):
        try:
            file_path = os.path.relpath(file_path, repo_root).replace('\\', '/')
        except ValueError:
            continue
    for pattern in watched_patterns:
        if matches_pattern(file_path, pattern):
            with open(queue_file, 'a') as f:
                f.write(file_path + '\n')
            break

PYEOF
PYTHON_EXIT=$?
echo "[queue] python3 exit=${PYTHON_EXIT}" >> "$DEBUG_LOG"

# Log rules files found, their patterns, and queue state
RULES_FILES=$(find "$REPO_ROOT/.claude/rules" -name "*.md" 2>/dev/null | tr '\n' ' ')
echo "[queue] rules files: ${RULES_FILES:-(none found)}" >> "$DEBUG_LOG"
echo "[queue] watched patterns:" >> "$DEBUG_LOG"
for f in $(find "$REPO_ROOT/.claude/rules" -name "*.md" 2>/dev/null); do
  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$f" | grep -A100 '^paths:' | grep '^ *-' | sed "s|^|  [$f]|"
done >> "$DEBUG_LOG" 2>/dev/null
echo "[queue] queue contents: $(cat "$QUEUE_FILE" 2>/dev/null || echo '(empty)')" >> "$DEBUG_LOG"

rm -f "$STDIN_TMP"
