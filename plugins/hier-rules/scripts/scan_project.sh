#!/usr/bin/env bash
# scan_project.sh
# Prints a clean directory tree for neuro-surgeon reconnaissance.
# Run from the project root.

echo "=== Project Directory Tree ==="
find . -type d \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/.next/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  -not -path '*/out/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/.venv/*' \
  -not -path '*/.tox/*' \
  -not -path '*/target/*' \
  -not -path '*/.claude/skills/*' \
  | sort

echo ""
echo "=== Existing .claude/rules/ Files ==="
if [ -d ".claude/rules" ]; then
  find .claude/rules -name "*.md" | sort
else
  echo "(none — .claude/rules/ does not exist yet)"
fi

echo ""
echo "=== Project Config Files ==="
for f in package.json pyproject.toml Cargo.toml README.md tsconfig.json \
          next.config.js next.config.ts vite.config.js vite.config.ts \
          .eslintrc.json .eslintrc.js tailwind.config.js tailwind.config.ts; do
  [ -f "$f" ] && echo "$f"
done
