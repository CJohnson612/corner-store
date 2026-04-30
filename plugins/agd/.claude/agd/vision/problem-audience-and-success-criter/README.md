# Problem, Audience, and Success Criteria

**Altitude:** 50K — Vision
**Status:** complete
**Minor Gate ID:** vision/problem-audience-and-success-criter
**Parent:** 50K major gate

---

## Intent

Establish what problem AGD solves, who experiences it, and how success will be measured — forming the foundation of the Vision before scope and assumptions are addressed.

---

## Decisions

- **Core problem:** The core problem is that users and AI agents jump to implementation without understanding what they want to build. AGD solves this by preserving intent and the "why" behind architecture, capabilities, and components so that AI coding agents can consume structured context rather than reconstructing it from the codebase.

- **Audience:** Primary users are software developers and people directing AI agents. Secondary users are non-technical founders and product people. AI-as-implementer (Claude Code, Codex) is treated as a first-class use case.

- **Success criterion (confirmed):** "The project documentation must be comprehensive enough that a competent practitioner — human or AI — with no prior context can independently implement, maintain, and improve the system using only the documented artifacts."

- **Scope (primary):** The tool's purpose is narrowly scoped to building out the artifact tree — not maintaining it (maintenance is possible in future but not the current focus).

- **Out of scope (deliberate and permanent):** Code generation, project management and task tracking, real-time collaboration, automated test generation, deployment and CI-CD pipelines, requirement gathering from external stakeholders, CI enforcement and gating, domain-specific templates.

- **Out of scope (currently, possible future):** Automatic diagram generation from existing code beyond the current bootstrap reverse-engineer skill.

- **AI-as-implementer:** AI-as-implementer (Claude Code, Codex) is a first-class use case — the artifact tree must serve AI agents as consumers, not only human practitioners.

- **Key assumption:** A well-documented project — not just what things do, but the why behind them — makes it easier to implement and maintain than a project with little to no documentation. This is the foundational belief the entire AGD approach rests on.

- **Key assumption:** AI agents can consume structured prose artifacts — current and near-future AI coding agents are capable enough to act meaningfully on well-structured documentation, not just code.

- **Key assumption:** The 'why' degrades faster than the 'what' — rationale and intent are what get lost over time and across context windows, not the code itself. AGD captures reasoning explicitly to counter this.

- **Key assumption:** A structured process reduces rework — catching misalignment at Vision costs less than catching it at Implementation. Altitude discipline has a real payoff.

- **OPEN — Structure vs. Substance:** A practitioner could complete all gate items without genuine design thinking, treating record-keeping as a substitute for reasoning. No mitigation defined at this altitude.

---

## Principles Referenced

---

## Deferred Details

---

## Children

| Minor Gate | Status |
|------------|--------|
