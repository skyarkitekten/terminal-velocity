# 05 — SLOs & Continuous Evaluation

> Outline + bullets. Uses the observability substrate from the infra epic
> (Log Analytics + App Insights) to define SLOs, surface them, and evaluate the
> agent **continuously in production**. Tracks placeholder epic #13.

## Goal

- Define SLOs for the agent, surface them on dashboards, and run scheduled
  evaluation against real prod traffic so regressions are caught after deploy,
  not just before.
- Provide the breach signal that drives the hill-climbing loop (doc 06).

## SLOs (starting set)

- **Task success rate** (per package-delivery scenario / SLA tier).
- **Latency** — p95 end-to-end response time.
- **Cost** — tokens per query / cost per resolved request.
- **Safety** — grounded-response rate, policy violations (= 0).

## Per-version telemetry (prerequisite)

- Stamp every request span with: agent name, **version id**, image **digest**
  (short), model deployment name.
- Slice every metric by version id — essential during traffic splits where two
  versions serve at once.
- Alert on **shape, not just rate**: a jump in avg response length or a drop in
  tool-invocation frequency often precedes a quality regression.

## Dashboards

- App Insights / Log Analytics workbooks: SLO tiles, per-version error/latency,
  cost dimensions (tag traces with tenant/customer where relevant).
- Sandbox right-sizing signals: CPU/memory peaks vs. allocation per version.

## Continuous evaluation

- Sample a % of prod conversations → offline grading on a schedule (reuse the
  golden graders from doc 04) → **drift detector** vs. last-known-good baseline.
- Run as a scheduled GitHub Actions / Foundry job; emit results to App Insights.

## Alerting

- Azure Monitor alerts when an SLO is at risk (error rate, p95 latency, drift,
  cost regression > threshold).
- A breached SLO is the trigger for doc 06's semi-automated loop.

## Acceptance

- [ ] SLOs defined and documented with targets.
- [ ] Per-version attributes on all traces.
- [ ] Workbook(s) showing SLOs + per-version slices.
- [ ] Scheduled continuous-eval job with drift alerting.

## Dependencies

- Observability (infra epic #14) — wired.
- Evaluations & graders (doc 04 / #11).
