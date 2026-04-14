# Corner Store Plugins

A collection of Claude Code plugins by Chase Johnson.

## Plugins

### hier-rules `v1.0.5`

Creates and maintains a `.claude/rules/` documentation system that mirrors your project's directory tree. Path-scoped rules files ensure each agent session only loads documentation relevant to its current working directory — keeping context lean without sacrificing coverage.

**Skills**

| Skill | Description |
|---|---|
| `/init-advanced` | Bootstraps the `.claude/rules/` tree for a codebase. Scans the project, plans the documentation structure, interviews the developer for non-obvious context, then writes rules files following a strict no-duplication hierarchy. |
| `rules-maintainer` | Automatically evaluates whether a rules file needs updating after source files are edited. Runs silently via hook and only acts when a change clears the significance threshold (new components, changed prop APIs, new modules, etc.). |

**How the rules system works**

Each rules file lives at a path that mirrors the source directory it documents (e.g. `src/components/` → `.claude/rules/components/components.md`). A YAML `paths:` frontmatter field tells Claude Code when to load each file. Three core laws govern the hierarchy:

1. **Breadth before depth** — parent files describe *when* to enter a child, not how to work there.
2. **No duplication** — if a fact lives in a child file, the parent must not repeat it.
3. **Descriptions are decisions** — every entry answers "when should an agent enter here?", not just what exists.

**Automation**

The plugin ships with two hooks:

- **PostToolUse** (`Write | Edit | Bash`) — queues any edited file that matches a watched `paths:` pattern.
- **Stop** — drains the queue at the end of each turn and triggers `rules-maintainer` if relevant files were changed. Clears the queue before blocking to prevent infinite loops.

## Installation

Install via the Claude Code plugin system using the marketplace config at `.claude-plugin/marketplace.json`, or point directly at a plugin directory.
