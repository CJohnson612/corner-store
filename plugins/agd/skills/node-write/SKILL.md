---
name: node-write
description: Creates or updates a node in the AGD fractal artifact tree. Writes the node README.md from a structured payload and updates the parent node's children.md. Called event-driven by the AGD session agent — not user-invocable.
user-invocable: false
---

# Node Write

This skill materializes minor gate nodes in the fractal artifact tree at `.claude/agd/`. Every minor gate in the session ledger has a corresponding directory node; this skill is what creates and maintains those nodes.

It is called event-driven — when a minor gate is created, when a decision is confirmed, when a minor gate is completed. It is never called speculatively.

---

## On Invocation

The agent passes a structured payload. Two operations are supported: `create` and `update`.

**Create payload:**
```
operation: create
minor_gate_id: [e.g. "vision/core-user-persona"]
minor_gate_name: [human-readable name]
altitude_id: [50k | 30k | 10k | 5k | 1k]
altitude_label: [Vision | Capabilities | Architecture | Design | Implementation]
parent_id: [parent minor gate id or major gate item id]
parent_name: [human-readable parent name]
parent_path: [relative path to parent node directory, or null for altitude roots]
status: open
intent: [one to three sentences — why this minor gate exists]
diagram: [Mermaid diagram string, or null if not applicable — see Diagram Generation below]
principles_referenced: []
```

**Update payload:**
```
operation: update
minor_gate_id: [existing minor gate id]
fields:
  status: [new status, if changed]
  diagram: [updated Mermaid string, or null if no change]
  decisions:
    - text: [decision text]
  principles_referenced:
    - name: [principle name]
      application: [one sentence]
  deferred_details:
    - text: [detail]
      target_altitude: [altitude id]
  intent: [updated intent, if revised]
```

---

## Diagram Generation

The session agent generates Mermaid diagram content before invoking node-write. This skill writes whatever diagram string the agent provides — it does not generate diagrams itself.

**When the agent provides a diagram:**
- 10K Architecture nodes — always. Every architecture node gets a component or integration diagram.
- 5K Design nodes — always. Every design node gets a sequence diagram showing the primary contract flow.
- 30K Capabilities nodes — when the capability has meaningful relationships to adjacent capabilities or the vision worth showing.
- 50K Vision, 1K Implementation — omit unless the agent determines a diagram adds clarity that prose cannot.

**Diagram types by altitude:**

| Altitude | Default Diagram Type | Shows |
|---|---|---|
| 30K Capabilities | `graph LR` flowchart | Capability and its relationship to adjacent capabilities and vision |
| 10K Architecture | `graph TD` flowchart | Component, its neighbors, integration points, data it owns |
| 5K Design | `sequenceDiagram` | Primary contract flow — preconditions, the interaction, postconditions |

If the agent passes `diagram: null`, the Diagram section is omitted from the README entirely (not left as a placeholder).

---

## Create Operation

1. **Resolve the directory path.**
   - Path format: `.claude/agd/[altitude-label-lowercase]/[minor-gate-slug]/`
   - Slug construction: lowercase the minor gate name, replace spaces with hyphens, strip non-alphanumeric characters except hyphens. Max 40 characters.
   - Example: minor gate "Core User Persona" at Vision → `.claude/agd/vision/core-user-persona/`

2. **Create the directory** if it does not exist, including all parent directories.

3. **Write README.md** using the node README template at `plugins/agd/schemas/node-readme-template.md`. Populate all fields from the payload.
   - If `diagram` is non-null: populate the `## Diagram` section with the provided Mermaid string inside a fenced code block tagged `mermaid`.
   - If `diagram` is null: omit the `## Diagram` section entirely.
   - Leave `Decisions`, `Principles Referenced`, and `Deferred Details` sections as empty placeholders — they will be filled on subsequent update operations.

4. **Write children.md** with the header only — no children yet:
   ```markdown
   # Children of [Minor Gate Name]

   | Minor Gate | Status |
   |------------|--------|
   ```

5. **Update the parent's children.md.** If `parent_path` is non-null, read the parent's `children.md` and append a row for this new minor gate:
   ```markdown
   | [Minor Gate Name](./[minor-gate-slug]/) | open |
   ```
   If the parent's `children.md` does not exist, create it with the header and this row.

6. **Return success** with the resolved path. The agent updates the session ledger separately.

---

## Update Operation

1. **Resolve the directory path** from the minor gate ID (same slug logic as create).

2. **Verify the directory exists.** If not: return `error: node_not_found [path]`.

3. **Read the existing README.md.**

4. **Apply field updates:**
   - `status` → update the Status line
   - `diagram` → if provided and non-null, replace the entire `## Diagram` section content. If the section does not exist, insert it after `## Intent`. If `diagram` is null, no change to the diagram section.
   - `decisions` → append each new decision to the Decisions section
   - `principles_referenced` → append each new principle to the Principles Referenced section
   - `deferred_details` → append each new detail to the Deferred Details section
   - `intent` → replace the Intent section content

5. **Write the updated README.md.**

6. **If status changed to `complete`:** update the parent's `children.md` to reflect the new status in that minor gate's row.

7. **Return success.** The agent updates the session ledger separately.

---

## Path Resolution Rules

| Minor Gate ID | Resolved Path |
|---|---|
| `vision/core-user-persona` | `.claude/agd/vision/core-user-persona/` |
| `capabilities/user-authentication` | `.claude/agd/capabilities/user-authentication/` |
| `architecture/user-auth/jwt-implementation` | `.claude/agd/architecture/user-auth/jwt-implementation/` |

Altitude label prefix is always the lowercase label (vision, capabilities, architecture, design, implementation), not the altitude ID (50k, 30k, etc.) — the label is more readable for human navigation.

---

## Error Handling

| Scenario | Action |
|---|---|
| Directory creation fails (permissions) | Return `error: directory_create_failed [path] [OS error]`. |
| README write fails | Return `error: readme_write_failed [path] [OS error]`. Surface to agent; do not silently skip. |
| Parent node not found when updating children.md | Create parent's children.md from scratch with this child as the first entry. Log a warning. |
| Minor gate ID produces a slug collision with an existing different minor gate | Return `error: slug_collision [existing_id] [new_id] [path]`. Agent must resolve before retrying. |
| Template file not found | Return `error: template_not_found`. Agent surfaces: "The node README template is missing — check that the AGD plugin is fully installed." |
| Update called on non-existent node | Return `error: node_not_found [path]`. Agent should call create first. |
| Diagram string is malformed Mermaid | Write it as-is. Do not validate Mermaid syntax — that is the agent's responsibility. |
