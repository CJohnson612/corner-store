---
name: init-advanced
description: Creates the .claude/rules/ documentation system for a codebase. This skill bootstraps context-optimized documentation for the project, updates specific module's documentation after a refactor, or audits the .claude/rules/ tree for stale or missing entries.
disable-model-invocation: true
allowed-tools: Agent
---

# init-advanced

You orchestrate the `.claude/rules/` documentation system — a directory-mirrored tree of context-efficient rules files that ensures agent sessions only load documentation relevant to their current task.

Your only job is orchestration. You do not explore the codebase, plan documentation, or write files yourself. You delegate to two specialized subagents and relay results to the user.

## The System Being Built

Every agent session has a finite context window. Documentation an agent doesn't need is pure waste. The `.claude/rules/` system solves this by mirroring the project's directory tree. An agent reads only the rules file for the directory it's actively working in.

**Three laws:**

1. **Breadth before depth.** Parent files describe _when_ to enter a child — not how to work there.
2. **No duplication.** If a fact lives in a child file, the parent must not repeat it.
3. **Descriptions are decisions.** Every entry must answer: "When should an agent enter here?"

**Path mapping:**

- Source `src/components/` → Rules `.claude/rules/components/components.md`
- Source `src/lib/utils/` → Rules `.claude/rules/lib/utils/utils.md`

Each rules file has a YAML frontmatter `paths:` field — this is what causes context to load only when the agent is working in the relevant directory.

## Your Workflow

### Step 1 — Spawn the Explorer

Use the Agent tool to invoke `hier-rules:hier-explorer`. Pass the absolute path of the current working directory in the prompt.

Wait for it to finish. It will write `.claude/hier-artifacts/exploration.yaml` and `.claude/hier-artifacts/dependency-graph.json`, then return a confirmation.

### Step 2 — Spawn the Planner (plan mode)

Use the Agent tool to invoke `hier-rules:hier-planner` with this prompt:

```
mode: plan
Working directory: <absolute path of current working directory>

The explorer has written the codebase map to .claude/hier-artifacts/exploration.yaml.
Read it, read representative source files, write .claude/hier-artifacts/hier-plan.md, and return your clarifying questions.
```

Wait for it to finish. It will return either a numbered list of questions or "No questions — proceed."

### Step 3 — Surface Questions to the User

Show the planner's questions to the user verbatim.

- If questions were returned: ask the user to answer them inline, or type "skip" for any they want to pass on. Wait for their response before continuing.
- If the planner returned "No questions — proceed.": tell the user what's about to be written and ask them to confirm before proceeding.

Do not proceed to Step 4 until the user has responded.

### Step 4 — Spawn the Planner (implement mode)

Use the Agent tool to invoke `hier-rules:hier-planner` with this prompt:

```
mode: implement
Working directory: <absolute path of current working directory>

User answers:
<paste the user's answers verbatim, or "none" if no questions were asked>

The approved plan is at .claude/hier-artifacts/hier-plan.md.
The exploration artifact is at .claude/hier-artifacts/exploration.yaml.
Write all files, incorporate the user's answers, then delete hier-plan.md only.
```

Wait for it to finish.

### Step 5 — Relay the Report

Show the planner's completion report to the user verbatim.

### Step 6 — Done

Tell the user:

> Rules files are ready. Run `/enrich-rules` to add mermaid component tree diagrams to your rules files.
