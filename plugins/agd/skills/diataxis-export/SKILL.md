---
name: diataxis-export
description: Reads the AGD artifact tree and produces Diataxis-structured documentation in the project's docs/ directory. Translates design artifacts into Explanation, Reference, How-To, and Tutorial documents that any stakeholder can read without knowledge of the AGD protocol. User-invocable.
user-invocable: true
---

# Diataxis Export

This skill converts a completed (or partial) AGD artifact tree into Diataxis-structured documentation. The output is written to the project's `docs/` directory and is intended for anyone who needs to understand the intent, structure, and operation of the project — not for practitioners working within AGD sessions.

The four Diataxis quadrants map naturally to the five AGD altitudes:

| Diataxis Quadrant | Source Altitudes | Purpose |
|---|---|---|
| Explanation | 50K Vision, 30K Capabilities, 10K Architecture | Understanding — what this is and why it's built this way |
| Reference | 10K Architecture, 5K Design | Information — precise descriptions of components and contracts |
| How-To | 1K Implementation | Task-oriented — how to set up, configure, and operate the system |
| Tutorial | 1K Implementation + agent synthesis | Learning — guided experience for newcomers (skeleton only) |

---

## On Invocation

Invoked by the practitioner when they want to publish design artifacts as readable documentation.

```
/agd:diataxis
```

Optional arguments:
```
output_dir: [path relative to project root — default: docs/]
sections: [all | explanation | reference | how-to | tutorial — default: all]
```

---

## Execution Steps

### Step 1 — Read the Ledger

Read `.claude/agd/agd-session.yml`. If not found, return `error: no_agd_session`. Surface: "No AGD session found in this project. Run `/agd:session` first."

Parse the ledger. Note which altitudes have status `in-progress` or `gate-passed`. Note which have status `open` (no work started) — these altitudes cannot contribute content and will be noted as gaps in the output.

### Step 2 — Read the Artifact Tree

For each altitude with status `in-progress` or `gate-passed`, read all minor gate node README files. Collect:
- Intent statements
- Decisions
- Principles referenced
- Deferred details
- Mermaid diagrams (where present)

Do not read nodes for altitudes with status `open`.

### Step 3 — Generate Explanation Documents

**File: `docs/explanation/project-overview.md`**

Source: 50K Vision nodes.

Content:
- What the project is and the problem it solves (from vision intent statements)
- Who experiences the problem (from vision nodes)
- What success looks like (from vision nodes — observable success criteria)
- What is explicitly out of scope (from vision deferred details marked out-of-scope, and boundary decisions)
- Key assumptions the design rests on (from vision decisions)

If 50K is incomplete: create the file with a note that vision work is in progress and available content follows.

**File: `docs/explanation/capability-overview.md`**

Source: 30K Capabilities nodes.

Content:
- The full capability map as a Mermaid diagram (synthesized from all 30K nodes — one diagram showing all capabilities and their relationships)
- For each capability: its name, what it does in business terms, and which part of the vision it serves
- Include any Mermaid diagrams from individual capability nodes

If 30K is incomplete: generate for available capabilities, note gaps.

**File: `docs/explanation/architecture-overview.md`**

Source: 10K Architecture nodes.

Content:
- A synthesized system-level Mermaid diagram combining all component diagrams into one overview (all components, their integration points, and data ownership — derived from individual 10K node diagrams)
- For each component: its name, responsibility, what data it owns, and which capabilities it supports
- Significant architectural decisions and their rationale (from 10K node decisions)
- Named principles that shaped the architecture (from 10K principles referenced)

If 10K is incomplete: generate for available components, note gaps.

### Step 4 — Generate Reference Documents

**File: `docs/reference/components.md`**

Source: 10K Architecture nodes.

Content:
- One section per component
- For each: name, responsibility, integration points (inputs and outputs), data owned, deployment characteristics
- Include the component's Mermaid diagram from its artifact node

**File: `docs/reference/contracts.md`**

Source: 5K Design nodes.

Content:
- One section per component with a design node
- For each: preconditions, postconditions, invariants, what happens on contract violation
- Include the sequence diagram from the design artifact node
- Entity invariants — business rules that must always hold

If 5K is incomplete or not started: create the file with a note that contract specifications are in progress, list which components have contracts defined and which do not.

### Step 5 — Generate How-To Documents

Source: 1K Implementation nodes.

For each implementation node, generate a How-To guide. The guide title is the minor gate name. Content is drawn from:
- The node's intent (the goal this guide achieves)
- Decisions in the node (configuration choices, steps that were decided)
- Deferred details resolved at 1K

**File per guide: `docs/how-to/[minor-gate-slug].md`**

Structure of each guide:
```markdown
# How To: [Minor Gate Name]

## Goal
[Intent statement from the node]

## Steps
[Derived from decisions and deferred details — presented as ordered steps where sequence is implied, or as configuration reference where it is not]

## Result
[What a practitioner should observe when this is done correctly — from the node's observable behavior notes if present]
```

If 1K is not started: create `docs/how-to/README.md` noting that implementation documentation will be generated once 1K work is complete.

### Step 6 — Generate Tutorial Skeleton

**File: `docs/tutorials/getting-started.md`**

Source: synthesized from 50K vision and 1K implementation nodes.

Tutorials are learning-oriented — they must be authored by a practitioner who has walked a newcomer through the experience. This skill generates a skeleton only.

Content:
- Introduction: what the reader will learn and what they will have built by the end (from 50K vision)
- Prerequisites: derived from 1K implementation dependencies
- Placeholder steps: one section per major How-To guide, with a note that each section must be expanded by a practitioner into a guided experience

Include a banner at the top:
```
> **Note for authors:** This is a generated skeleton. Each section below maps to a How-To guide
> and must be expanded into a guided, example-driven tutorial experience. The skeleton preserves
> the correct sequence and prerequisites — the narrative is yours to write.
```

### Step 7 — Write Index Files

**File: `docs/README.md`** (create or update if exists)

A navigation index pointing to all generated files:
- What documentation is available
- Which altitudes the documentation was derived from
- Any gaps (altitudes not yet completed)
- Generation timestamp and AGD session reference

### Step 8 — Return Result

```
DIATAXIS EXPORT RESULT
output_dir: [path]
files_written:
  explanation:
    - [file path]
  reference:
    - [file path]
  how-to:
    - [file path]
  tutorial:
    - [file path]
gaps:
  - altitude: [id]
    label: [label]
    status: [open | in-progress]
    impact: [which documents are incomplete as a result]
```

Surface the result to the practitioner with a brief summary:
> "Documentation generated in `docs/`. [N] files written across [quadrants covered]. [If gaps:] Note: [altitude] work is not yet complete — [document names] are partial."

---

## Handling Partial Artifact Trees

This skill is designed to be run at any point in the design process, not only when all altitudes are complete. Partial documentation is better than no documentation.

Rules for partial content:
- If an altitude has no work started: skip it entirely. Note the gap in the output.
- If an altitude is `in-progress`: generate from whatever nodes exist. Add a visible banner to each affected file: `> **In progress:** This section reflects design work through [date]. It will be updated as the design develops.`
- Never generate empty sections. A section either has content or is absent.
- Never fabricate content. If the artifact nodes do not contain the information needed for a section, omit the section and note it in the export result.

---

## Error Handling

| Scenario | Action |
|---|---|
| No AGD session found | Return `error: no_agd_session`. Surface instructions to start a session. |
| Ledger found but no completed or in-progress altitudes | Surface: "No design work has been recorded yet. Complete at least 50K Vision before exporting." |
| Output directory exists with existing docs | Overwrite generated files. Do not delete files that were not generated by this skill. |
| Output directory cannot be created (permissions) | Return `error: output_dir_create_failed [path] [OS error]`. |
| Individual artifact node README unreadable | Skip that node. Note it in the export result gaps. Continue with other nodes. |
| docs/README.md exists with custom content | Append the navigation index to the bottom of the existing file rather than overwriting. |
