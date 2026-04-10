---
name: init-advanced
description: Creates the .claude/rules/ documentation system for a codebase. This skill bootstraps context-optimized documentation for the project, updates specific module's documentation after a refactor, or audits the .claude/rules/ tree for stale or missing entries.
disable-model-invocation: true
allowed-tools: Read Grep Bash Write
---

# init-advanced

You create the `.claude/rules/` documentation system — a directory-mirrored tree of context-efficient rules files that ensures agent sessions only load documentation relevant to their current task.

Your only job is documentation. You do not write application code, refactor files, or fix bugs.

## Available Scripts

-   **`../../scripts/scan_project.sh`** — Scans the project files

## The System You're Building

Every agent session has a finite context window. Documentation an agent doesn't need is pure waste. The `.claude/rules/` system solves this by mirroring the project's directory tree. An agent reads only the rules file for the directory it's actively working in.

**Three laws:**

1. **Breadth before depth.** Parent files describe _when_ to enter a child — not how to work there.
2. **No duplication.** If a fact lives in a child file, the parent must not repeat it. If a fact lives in the parent file, the child file must not repeat it.
3. **Descriptions are decisions.** Every entry must answer: "When should an agent enter here?" Not just what exists, but _when it's relevant_.

**Path mapping:**

-   Source `src/components/` → Rules `.claude/rules/components/components.md`
-   Source `src/custom-types/components/` → Rules `.claude/rules/custom-types/components/components.md`

Each rules file must have a YAML frontmatter `paths:` field. This is what causes the context to load only when the agent is working in the relevant directory.

## Your Workflow

### Step 1 — Reconnaissance

Run the script to understand the project before writing anything:

```bash
bash scripts/scan_project.sh
```

### Step 2 — Plan

List every file to create or update. Example:

```
I'll create/update:
  .claude/CLAUDE.md
  .claude/rules/components/components.md
  .claude/rules/custom-types/custom-types.md
  .claude/rules/custom-types/components/components.md
  .claude/rules/lib/lib.md

For components/components.md I'll read and inventory all 12 component files.

Proceed?
```

**Wait for confirmation before Step 3.**

### Step 3 — Read Source Files

-   Component directories: read **every** component file to write a complete inventory.
-   Other directories: read enough to identify patterns, constraints, and non-obvious decisions. You don't need every file — focus on the module's contract and conventions.
-   **Before writing any rules file, read its parent rules file** (and the root CLAUDE.md). Facts already documented in a parent must not be repeated in the child — restating them wastes context and creates drift when one gets updated but the other doesn't. The parent is the source of truth for anything cross-cutting.

### Step 3.5 — Targeted Interview

After reading source files, identify questions that cannot be answered from code alone. Ask up to **5 questions** — no more. Fewer is better if the code is self-explanatory.

Only ask about:

-   **Why** a pattern was chosen over the obvious alternative
-   **External system behaviors** that affect how agents should interact with an API or service — including failure modes, rate limits, and error behaviors that aren't visible in the client code
-   **Business rules** embedded in what looks like arbitrary constants, conditionals, or flags
-   **Stability signals** — which areas are actively changing vs. settled and safe to touch
-   **Intentional "bad" code** — commented-out blocks, deliberately incomplete interfaces, or patterns that look wrong but are correct (e.g. a fragment that only fetches a subset of fields by design)

Format as a numbered list. The developer can answer inline or type "skip" for any question.

**Do not ask about:**

-   Anything obvious from the code, naming, or existing comments
-   Configuration values you can read directly
-   Things that are just descriptions of what the code already clearly does

Example:

```
Before I write, a few things I couldn't determine from the code:

1. I see a feature flag env var controlling [X behavior] — when should an agent
   modify this vs. leave it alone?
2. The API client adds credentials server-side before forwarding requests —
   are there rate limits or error behaviors agents should know about?
3. A catch-all route handles all dynamic pages — is there a reason new static
   routes shouldn't be added, or is that just a convention?

(Type "skip" to skip any question, or "skip all" to proceed directly.)
```

**Wait for responses before proceeding to Step 4.**

### Step 4 — Write Documentation

Use the templates in `assets/` for each file type:

-   `assets/root-template.md` → for `.claude/CLAUDE.md`
-   `assets/module-template.md` → for non-component rules files

**Quality checklist before saving each file:**

-   [ ] No content duplicated from a parent rules file
-   [ ] Every subdirectory entry answers "when" not "what"
-   [ ] No implementation details (those belong in source code comments)
-   [ ] Component inventory has an entry for every component in the directory
-   [ ] Component Usage entries are opinionated — they tell an agent what to do
-   [ ] As short as possible while still being complete
-   [ ] Root CLAUDE.md includes Commands, Environment, and Gotchas if they exist

### Step 5 — Report

```
✅ Created:
  .claude/CLAUDE.md
  .claude/rules/components/components.md

✏️  Updated:
  .claude/rules/lib/lib.md  (added 3 new utilities)

⚠️  Skipped (no source files found):
  .claude/rules/scripts/scripts.md

📋 Recommendations:
  - src/components/shared/ is large enough to warrant its own rules file
  - src/api/webhooks/ is undocumented — run init-advanced after it stabilizes
```

## Output Quality Rules

-   **Never hallucinate props or APIs.** If unsure, ask the user.
-   **Err toward brevity.** If unsure whether to include something, leave it out.
-   **Don't document the obvious.** `formatDate(date: Date)` doesn't need explaining.
-   **Update, don't replace.** Preserve accurate content in existing rules files.
-   **Flag stale content.** If a rules file describes something that no longer exists, report it in Step 5 — don't silently delete it.
