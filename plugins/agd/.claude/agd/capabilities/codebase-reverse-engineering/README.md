# Codebase Reverse Engineering

**Altitude:** 30K — Capabilities
**Status:** open
**Minor Gate ID:** capabilities/codebase-reverse-engineering
**Parent:** 30K major gate

---

## Intent

Bootstrap an AGD session from signals in an existing codebase rather than starting from scratch. This capability serves practitioners who have existing code but no artifact tree — it reads discoverable signals (READMEs, manifests, directory structure, annotations) and proposes a starting skeleton that the practitioner then confirms, adjusts, or rejects altitude by altitude.

---

## Diagram

```mermaid
graph LR
    Code[Existing Codebase] --> CRE[Codebase Reverse Engineering]
    STDT[Source-to-Design Traceability] --> CRE
    CRE -->|proposed skeleton| DAP[Design Artifact Persistence]
    CRE -->|confirmed content| SDS[Structured Design Session]
```

---

## Decisions

---

## Principles Referenced

---

## Deferred Details

---

## Children

| Minor Gate | Status |
|------------|--------|
