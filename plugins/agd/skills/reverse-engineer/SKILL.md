---
name: reverse-engineer
description: Scans an existing project and produces a proposed skeleton AGD session ledger based on discoverable signals — README, package manifests, directory structure, and any existing @agd: annotations. Called by the AGD session agent during onboarding of an existing codebase. Not user-invocable.
user-invocable: false
---

# Reverse Engineer

This skill infers design intent from an existing codebase without reading individual source files. It looks for high-signal artifacts — documentation, package manifests, directory structure, and any existing `@agd:` annotations — and produces a proposed skeleton ledger the session agent can present to the practitioner for review.

Every inference is marked `source: inferred`. Nothing is treated as confirmed until the practitioner says so.

---

## On Invocation

Called by the session agent during onboarding when the practitioner indicates an existing codebase is present.

```
project_root: [absolute path to the project root]
```

---

## Scan Steps

Execute in order. Record findings from each step. Proceed through all steps regardless of what is found — a step with no findings is still useful information.

### Step 1 — Check for Existing AGD State

Look for `.claude/agd/agd-session.yml` at the project root.

- If found: return immediately with `status: already_initialized` and the ledger path. The session agent will read the existing ledger rather than propose a new one.
- If not found: continue.

### Step 2 — Read the Top-Level README

Look for `README.md` or `README.rst` or `README.txt` at the project root. Read it if found.

Extract:
- **Project name** — usually the H1 heading or first bold text
- **Project description** — first paragraph or "About" section
- **Stated purpose or problem** — any language describing what the project does or who it serves
- **Explicit out-of-scope statements** — any "this does not..." or "out of scope" language

If no README exists: record `readme: not_found`.

### Step 3 — Read Package Manifests

Look for any of the following at the project root or one level deep:

| File | What to extract |
|---|---|
| `package.json` | `name`, `description`, `dependencies` keys (top-level only) |
| `pyproject.toml` or `setup.py` | `name`, `description` |
| `Cargo.toml` | `[package]` name and description |
| `go.mod` | module name |
| `*.gemspec` | `name`, `summary` |
| `pom.xml` | `artifactId`, `description` |
| `build.gradle` | `rootProject.name` |

Record: language ecosystem, project name (if README didn't provide one), and any dependency names that hint at architectural concerns (e.g., database drivers, HTTP frameworks, messaging libraries).

### Step 4 — Survey Directory Structure

List the top-level directories only (not recursive). Exclude hidden directories (`.git`, `.claude`, `.env`, etc.), build output directories (`dist`, `build`, `target`, `out`, `node_modules`, `__pycache__`), and dependency directories.

For each remaining directory, record its name. These are candidate component boundaries for 10K Architecture.

Also note: does a `docs/` or `documentation/` directory exist? If so, list its immediate contents (file names only, not recursive). These may contain existing design artifacts.

### Step 5 — Scan for @agd: Annotations

Search all files in the project for lines matching `@agd:\s*([^\s]+)`. Collect all unique annotation paths found.

- If any exist: the project has partial AGD coverage. Record the paths found.
- These annotation paths may correspond to an incomplete or abandoned ledger.

### Step 6 — Check for Existing Design Documents

In the `docs/` directory (if found in Step 4), look for files with names suggesting design content:

- Files containing: `vision`, `architecture`, `design`, `capability`, `adr`, `decision`, `rfc`
- File types: `.md`, `.txt`, `.rst`

List them by name only — do not read their contents.

---

## Building the Proposed Skeleton

After all scan steps complete, construct a proposed skeleton ledger using the findings.

**Rules:**
- Only propose content for an altitude if there is a clear signal for it
- Mark every proposed value `source: inferred` — nothing is confirmed
- Leave altitudes with no signals at `status: not-started` with no proposed content
- Do not invent capabilities, components, or design decisions — only surface what the scan found

**Altitude mapping:**

| Altitude | Propose from |
|---|---|
| 50K Vision | README description, project name, stated purpose, out-of-scope language |
| 30K Capabilities | Dependency names (e.g., "uses Stripe → payment processing capability"), docs file names suggesting capability areas |
| 10K Architecture | Top-level directories as candidate components |
| 5K Design | No signal available from this scan — leave not-started |
| 1K Implementation | Package manifest ecosystem (language, runtime) |

---

## Return Format

```
REVERSE ENGINEER RESULT
project_root: [path]
status: [proposed | already_initialized | no_signals]

signals_found:
  readme: [found | not_found]
  manifests: [list of files found, or none]
  top_level_dirs: [list]
  agd_annotations: [list of paths found, or none]
  design_docs: [list of file names, or none]

proposed_skeleton:
  project: [inferred name or null]
  altitudes:
    - altitude_id: 50k
      label: Vision
      status: [not-started | has-proposals]
      proposals:
        - field: vision_statement_hint
          value: [text]
          source: inferred
          signal: [e.g., "README first paragraph"]
        - field: out_of_scope_hint
          value: [text]
          source: inferred
          signal: [e.g., "README out-of-scope section"]

    - altitude_id: 30k
      label: Capabilities
      status: [not-started | has-proposals]
      proposals:
        - field: capability_hint
          value: [text]
          source: inferred
          signal: [e.g., "dependency: stripe"]

    - altitude_id: 10k
      label: Architecture
      status: [not-started | has-proposals]
      proposals:
        - field: component_hint
          value: [directory name]
          source: inferred
          signal: [e.g., "top-level directory"]

    - altitude_id: 5k
      label: Design
      status: not-started
      proposals: []

    - altitude_id: 1k
      label: Implementation
      status: [not-started | has-proposals]
      proposals:
        - field: ecosystem
          value: [e.g., "Node.js / TypeScript"]
          source: inferred
          signal: [e.g., "package.json"]

notes:
  - [any observations worth surfacing — e.g., "design docs found in /docs — practitioner may want to review before starting"]
  - [e.g., "3 @agd: annotations found — these reference nodes not yet in a ledger"]
```

If `status: already_initialized`: return only the `project_root`, `status`, and ledger path. No skeleton.

If `status: no_signals`: return only `project_root`, `status`, and a note that no useful signals were found. The session agent will begin at 50K with no prefill.

---

## Agent Usage

The session agent receives the skeleton and presents it to the practitioner altitude by altitude:

- For each altitude with proposals: "Based on what I found, here's a starting point for [altitude] — [proposed value]. Does this capture it, or should we adjust?"
- Practitioner confirms, adjusts, or rejects each proposal
- Only confirmed content goes into the actual ledger — inferred content is never written without practitioner approval
- After all altitudes are reviewed: the agent creates the ledger via the normal session start path, populated with whatever was confirmed

The agent does not surface the raw result block to the practitioner — it uses it as structured input to drive a conversation.

---

## Error Handling

| Scenario | Action |
|---|---|
| `project_root` not found or not a directory | Return `error: invalid_project_root [path]`. |
| README exists but is empty | Record `readme: found_empty`. Treat as not found for inference purposes. |
| Manifest file found but unparseable | Record the file as found, skip extraction, note parse failure in `notes`. |
| Directory listing fails (permissions) | Record `error: directory_read_failed [path]`. Continue with other steps. |
| `@agd:` annotation scan fails | Record `error: annotation_scan_failed`. Continue with other steps. |
| All steps return no useful signals | Return `status: no_signals`. Not an error — agent handles gracefully. |
