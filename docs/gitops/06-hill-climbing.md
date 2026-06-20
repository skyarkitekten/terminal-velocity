# 06 — Semi-Automated Hill-Climbing Loop

> Outline + bullets. Closes the GitOps loop from the
> [philosophy](./00-philosophy.md): an SLO breach automatically becomes an issue,
> an agent is assigned to investigate and propose a fix, and a human approves the
> promotion. Tracks placeholder epic #10 — the furthest-out horizon.

## Goal

- Make improvement continuous and mostly automated while keeping a human in the
  loop for promotion.
- "We only step downhill (rollback) with good reason." Every change is a step;
  promote → measure attributed delta → keep or roll back.

## The loop

1. **Breach** — a prod SLO/eval/drift alert fires (doc 05).
2. **File** — automation opens a GitHub issue with context: failing traces,
   eval diffs, the version id/digest in play.
3. **Assign** — an agent is assigned to triage and propose a change
   (prompt/tool/model lever). A prompt optimizer / Agent Optimizer can suggest
   instruction edits.
4. **PR** — the proposed change flows through the normal agent pipeline (docs
   03–04): build candidate at 0% traffic, run evals + guardrails + red team.
5. **Human approval** — required reviewer approves promotion to prod.
6. **Canary & attribute** — promote behind a traffic split; measure the delta
   against control; keep or roll back.

## Attribution discipline (from the feature notes)

- **One step in flight** at a time across the system — concurrent promotions
  destroy attribution.
- Evals must score the **system objective**, not per-component local objectives
  (avoid Goodhart / local optima).
- Escalation guard: N consecutive rollbacks on a slice → gate that slice and tell
  a human its thresholds may no longer match reality.

## What this needs first

- SLOs + continuous eval + drift alerting (doc 05).
- A green agent pipeline with eval/guardrail gates and tested rollback
  (docs 03–04).
- Issue templates + automation (Actions / Foundry) to file and assign.

## Acceptance

- [ ] SLO breach auto-files an issue with traces + failing evals.
- [ ] Agent auto-assignment proposes a change via PR.
- [ ] Promotion requires human approval and runs the full gate set.
- [ ] Canary attribution + rollback decision is recorded.

## Status

Placeholder, furthest horizon. Depends on docs 03–05 being green.
