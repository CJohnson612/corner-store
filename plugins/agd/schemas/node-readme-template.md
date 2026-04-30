# [Minor Gate Name]

**Altitude:** [50K — Vision | 30K — Capabilities | 10K — Architecture | 5K — Design | 1K — Implementation]
**Status:** [open | in-progress | complete | needs-review | blocked]
**Minor Gate ID:** [e.g. vision/core-user-persona]
**Parent:** [Parent minor gate name and link, or major gate item ID if a root minor gate]

---

## Intent

[Why this minor gate exists. One to three sentences tracing the purpose of this minor gate back to the parent that spawned it. A reader should understand what question this minor gate is answering and why it matters at this altitude.]

---

## Diagram

[Mermaid diagram. Populated at creation for Architecture and Design nodes; omitted at other altitudes unless the agent determines a diagram adds clarity.

At 10K Architecture: component boundary diagram showing this component's relationships to its neighbors, integration points, and data ownership boundaries.
At 5K Design: sequence diagram showing the primary contract flows — preconditions, the interaction, and postconditions — between this component and the components it depends on.
At 30K Capabilities: capability map showing how this capability relates to adjacent capabilities and traces to the vision.]

```mermaid
[diagram content]
```

---

## Decisions

[Significant choices made while working through this minor gate. Each decision should record what was decided and the reasoning behind it. If a decision was formally recorded elsewhere, link to it here.]

- **[Decision]:** [What was decided and why]

---

## Principles Referenced

[Named principles from the principles library that informed the work at this node. Use exact principle names.]

- [Principle Name] — [one sentence on how it applied here]

---

## Deferred Details

[Things that surfaced during this minor gate that belong at a lower altitude. Capturing them here prevents loss without violating altitude discipline.]

- [Detail] — belongs at [altitude]

---

## Children

[List of child minor gates that this minor gate spawned. See children.md for full status detail.]

| Minor Gate | Status |
|------------|--------|
| [Child Minor Gate Name](./child-slug/) | open |
