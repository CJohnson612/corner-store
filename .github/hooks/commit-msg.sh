#!/bin/sh                                                               
  commit_regex='^(feat|fix|chore|docs|style|refactor|test|ci|build|revert)
  (\(.+\))?: .+'                                                          
  if ! grep -qE "$commit_regex" "$1"; then
    echo "ERROR: Commit message must follow Conventional Commits format."
    echo "  Examples: feat: add caching, fix: typo, chore: bump version"
    echo "  See: https://www.conventionalcommits.org"
    exit 1
  fi
  Then chmod +x .git/hooks/commit-msg. This blocks the commit immediately
  if the format is wrong.

  GitHub Actions (enforces on PRs for the whole team) — add
  .github/workflows/conventional-commits.yml:
  name: Conventional Commits
  on:
    pull_request:
      types: [opened, edited, synchronize]
  jobs:
    check:
      runs-on: ubuntu-latest
      steps:
        - uses: amannn/action-semantic-pull-request@v5
          env:
            GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}