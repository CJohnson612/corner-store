---
name: gate-check
description: Evaluates whether a major gate at a given altitude is ready to pass. Checks all fixed major gate items and all minor gates at that altitude for completion. Returns gate status and remaining blockers. Called by the AGD session agent — not user-invocable.
user-invocable: false
---

# Gate Check

This skill evaluates whether an altitude's major gate can be passed. It has two responsibilities: it holds the fixed major gate check questions for all five altitudes, and it evaluates readiness by inspecting the session ledger. It does not pass the gate — that is the agent's decision, made with the practitioner.

---

## On Invocation

Called by the session agent with an altitude ID: `50k | 30k | 10k | 5k | 1k`.

Return a structured result the agent uses to present the gate status and drive the conversation.

---

## Evaluation Steps

1. **Read the session ledger** at `.claude/agd/agd-session.yml`. If not found, return `error: ledger_not_found`.

2. **Find the altitude entry** matching the provided altitude ID.

3. **Check major gate items.** For each item in `major_gate.items`: is the status `checked`? Collect unchecked items.

4. **Check minor gates.** For each minor gate in `minor_gates[]` at this altitude: is the status `complete`? Collect incomplete minor gates. A minor gate with status `needs-review` or `blocked` counts as incomplete.

5. **Determine gate status:**
   - `passed` — all major gate items checked AND all minor gates complete AND `gate_passed_at` is set
   - `ready` — all major gate items checked AND all minor gates complete AND `gate_passed_at` is null (gate has not been formally passed yet)
   - `blocked` — one or more major gate items unchecked OR one or more minor gates incomplete
   - `not-started` — no minor gates exist and no major gate items have been checked

6. **Return the result:**

```
GATE CHECK RESULT
altitude: [id]
label: [label]
gate_status: [passed | ready | blocked | not-started]
major_gate_remaining:
  - [item text]
  [repeat for each unchecked item, or "none" if all checked]
minor_gates_incomplete:
  - id: [minor gate id]
    name: [minor gate name]
    status: [status]
  [repeat for each incomplete minor gate, or "none"]
blocker_count: [total number of remaining items across both lists]
```

---

## Fixed Major Gate Definitions

These questions are the authoritative source for all major gate items. When the session agent creates a new ledger, it populates `major_gate.items` for each altitude from these definitions.

### 50,000 ft — Vision

Grounded in: Cooperative Game (Cockburn), Last Responsible Moment (Poppendieck), Value Stream Thinking (Poppendieck)

1. Can this vision be explained to a non-technical stakeholder without confusion?
2. Does the problem statement resonate with the people who experience the problem?
3. Are the success criteria observable without technical instrumentation?
4. Are the boundaries clear enough to prevent scope creep?
5. Have the key assumptions embedded in the vision been named and acknowledged?
6. Is the problem statement free of solution-domain language? *(A vision that specifies technology has descended too early.)*

### 30,000 ft — Capabilities

Grounded in: Ubiquitous Language (Evans), Bounded Contexts (Evans), Use Cases as Goals (Jacobson)

1. Does every capability trace to something in the vision statement?
2. Are there aspects of the vision not covered by any capability?
3. Is every capability described in business terms, not solution terms?
4. Could a business stakeholder review this map and confirm it is complete and correct?
5. Are the boundaries between capabilities clear — does each have a single clear owner?

### 10,000 ft — Architecture

Grounded in: Evolutionary Architecture (Ford), Bounded Contexts (Evans), Independent Deployability (Newman), Consistency Boundaries (Helland)

1. Does every capability from 30K map to at least one component?
2. Do component boundaries exhibit high cohesion and low coupling?
3. Are all integration points between components identified with enough detail to design contracts?
4. Is it clear which component owns each piece of data?
5. Can each component be independently deployed or replaced without coordinated changes to others?
6. Have the significant architectural decisions been identified for formal recording?

### 5,000 ft — Design

Grounded in: Design by Contract (Meyer), SOLID Principles (Martin), Test-Driven Development (Beck), Last Responsible Moment (Poppendieck)

1. Does every component have explicitly defined preconditions, postconditions, and invariants?
2. Does every interface contract specify what happens when the contract is violated?
3. Can each component's internal implementation change without affecting other components' behavior?
4. Are entity invariants — business rules that must always hold — documented explicitly?
5. Is there a clear test strategy for each component — what will be tested and at what level?
6. Have implementation details been deferred to 1K rather than decided here?

### 1,000 ft — Implementation

Grounded in: Continuous Delivery (Humble), Observability (Gregg), Evolutionary Architecture (Ford), AI-First Development (Karpathy)

1. Does the implementation match the component design documented at 5K, or are divergences recorded?
2. Are fitness functions in place for the architectural properties declared at 10K?
3. Is the system observable — can failures be diagnosed from runtime signals without source access?
4. Is the deployment process repeatable without manual steps?
5. Are implementation decisions not anticipated at 5K captured in the relevant artifact nodes?

---

## Error Handling

| Scenario | Action |
|---|---|
| Ledger not found | Return `error: ledger_not_found`. Agent handles recovery. |
| Altitude ID not recognized | Return `error: unknown_altitude [id]`. |
| Minor gate status value not recognized | Treat as incomplete. Note in result. |
| Ledger is malformed YAML | Return `error: ledger_parse_failed [detail]`. Agent surfaces the file path and parse error. |
