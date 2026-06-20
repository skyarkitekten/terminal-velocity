# 04 — Evaluations & Guardrails as CI Gates

> Outline + bullets. Turns agent quality and safety into **blocking gates** in
> the delivery pipeline (doc 03). Tracks placeholder epic #11. This is the step
> the reference posts call *the* core difference between agent CI/CD and
> traditional CI/CD.

## Goal

- No agent version is promoted unless it passes evaluation and safety gates.
- Fill the eval gate stubbed in `agent-cd.yml` (#28).
- Treat the eval suite like unit tests: **a failure stops the pipeline.**

## The golden dataset (first-class artifact)

- 20–50 JSONL scenarios: input + reference answer / must-include facts / rubric.
- Versioned in `src/agents/<name>/evals/dataset.jsonl`; its hash is recorded in
  the deployment manifest.
- **Maintained as the agent evolves** — stale datasets give misleading pass/fail.

## Graders

- Foundry built-in evaluators: exact match, similarity, LLM-as-judge,
  groundedness, safety.
- **Pin the grader's model deployment** to prevent grader drift.
- Defined in `evals/graders.yaml`.

## Thresholds (start from P2, tune from an advisory phase)

| Category | Metric | CI (dev) | Prod gate |
| --- | --- | --- | --- |
| Quality | Hallucination rate | < 5% | < 3% |
| Quality | Task completion | > 90% | > 95% |
| Safety | Grounded response rate | > 95% | > 98% |
| Safety | Policy violations | 0 | 0 |
| Performance | p95 latency | < 4000 ms | < 3000 ms |
| Cost | Tokens / query | track | alert > 20% regression |

- **Hard floors** on safety/groundedness/policy (any regression fails).
- **Relative** floor on quality (no more than X% drop vs. last-known-good).

## Guardrails (safety plane)

- Content-safety filters on the model deployment; "0 policy violations" is a
  hard gate.
- Azure Policy / governance checks that block deployment automatically.
- Least-privilege RBAC + Entra Agent Identity per version (already in infra).

## Red teaming (adversarial gate)

- Curated adversarial / jailbreak / prompt-injection suite, run on a schedule
  and before prod promotion.
- Tooling options: Azure AI Red Teaming Agent / PyRIT-style scans.
- Failures open a tracked issue (feeds the hill-climbing loop, doc 06).

## Wiring into CI/CD

- **PR (CI)**: build candidate at `--traffic 0` → `run_evals.py` →
  `check_eval_gates.py` (exit 1 on failure) → advisory at first, then blocking.
- **Pre-promotion (CD)**: re-run against a stricter scenario set before prod.
- Both report results to the PR / job summary so reviewers see the diff.

## Phased rollout

1. Advisory evals (collect signal, no blocking).
2. Flip to blocking with tuned thresholds.
3. Add safety/policy hard gates.
4. Add scheduled red-team suite.

## Acceptance

- [ ] Golden dataset + graders committed and hashed into the manifest.
- [ ] `check_eval_gates.py` fails CI on threshold breach.
- [ ] Policy-violation gate blocks promotion.
- [ ] Red-team suite runs on a schedule and on prod promotion.
