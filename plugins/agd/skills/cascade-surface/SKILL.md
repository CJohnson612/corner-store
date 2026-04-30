---
name: cascade-surface
description: Given a minor gate ID that has changed, walks the full child tree and returns all affected descendant minor gates across all altitudes. Does not modify anything — surfaces only. Called by the AGD session agent when a minor gate is modified after having children.
user-invocable: false
---

# Cascade Surface

This skill surfaces the downstream impact of a minor gate change. When a parent minor gate is modified — its intent revised, its decisions changed, or its status altered — every descendant minor gate that was derived from it may need to be reviewed. This skill finds all of them and returns them to the agent for practitioner review.

It never modifies the ledger or artifact tree. Discovery only.

---

## On Invocation

Called by the session agent with a changed minor gate ID.

```
changed_minor_gate_id: [minor gate id]
change_type: [intent_revised | decision_changed | status_changed | minor_gate_deleted]
```

---

## Walk Steps

1. **Read the session ledger** at `.claude/agd/agd-session.yml`. If not found, return `error: ledger_not_found`.

2. **Locate the changed minor gate** in the ledger. If not found, return `error: minor_gate_not_found [id]`.

3. **Read the `children` array** of the changed minor gate. This is the direct children list.

4. **Recursively walk all descendants.** For each child ID:
   - Locate the minor gate in the ledger
   - Add it to the affected list with its metadata
   - Recurse into its own `children` array
   - Continue until no more children exist

5. **Build the affected list.** Each entry contains:
   ```
   - minor_gate_id: [id]
     minor_gate_name: [name]
     altitude_id: [id]
     altitude_label: [label]
     status: [current status]
     parent_id: [direct parent id]
     path: [artifact node path]
     depth: [hops from the changed minor gate — 1 for direct children, 2 for grandchildren, etc.]
   ```

6. **Sort by depth ascending** — direct children first, then grandchildren. This is the order the agent presents them to the practitioner (closest impact first).

7. **Return the result:**

```
CASCADE SURFACE RESULT
changed_minor_gate_id: [id]
change_type: [type]
affected_count: [total number of descendants]
affected_minor_gates:
  - minor_gate_id: [id]
    minor_gate_name: [name]
    altitude_id: [id]
    altitude_label: [label]
    status: [status]
    parent_id: [id]
    path: [path]
    depth: [N]
  [repeat for each affected minor gate]
```

If no children exist: return `affected_count: 0` with an empty list. The agent handles this gracefully — no cascade needed.

---

## Agent Usage

The agent receives the cascade surface result and uses it to drive the practitioner review. Default behavior:

- Surface affected minor gates one at a time, depth-first (shallowest first)
- For each: "This minor gate was derived from the one that just changed. Does it still hold as written, or does it need to be revised?"
- Practitioner responds; agent updates the ledger and artifact node accordingly

Opt-in auto-update: if the practitioner says "auto-update all" or similar, the agent applies its own reasoning to update each affected minor gate and presents a diff. The practitioner confirms or corrects the diff before any changes are written.

Regardless of path chosen, the agent marks each reviewed minor gate's `cascade_flagged` field as `false` in the ledger after resolution.

---

## Error Handling

| Scenario | Action |
|---|---|
| Ledger not found | Return `error: ledger_not_found`. |
| Changed minor gate not found in ledger | Return `error: minor_gate_not_found [id]`. |
| Child ID in `children` array not found in ledger | Include in affected list with `status: missing_from_ledger`. Note the orphaned reference. |
| Circular reference detected in child tree | Return `error: circular_reference [minor_gate_id]`. This indicates ledger corruption — agent surfaces the error and the ledger path. |
| Ledger is malformed YAML | Return `error: ledger_parse_failed [detail]`. |
