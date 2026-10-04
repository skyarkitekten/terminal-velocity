# Issue Prioritization and Improvement Plan

This plan sequences the 20 issues in scope: existing issues #57–#71 and
improvement issues #74–#78. Estimates are rough person-hours for implementation,
excluding review and waiting time. The schedule assumes one primary engineer,
with documentation and observability work happening in parallel; it is a target,
not a commitment.

## Priority levels

- **Critical** — required to establish a reliable foundation; start immediately.
- **High** — required to deliver and validate a usable agent path.
- **Medium** — documentation, governance, and observability that improve
  readiness and contributor experience.
- **Low** — continuous improvement automation, after the standard delivery and
  safety gates are working.

## Issue breakdown

| Priority | Issue | Estimate | Dependencies / sequencing |
| --- | --- | ---: | --- |
| Critical | [#58 Package skeleton](https://github.com/skyarkitekten/terminal-velocity/issues/58) | 2 h | Foundation for agent and tool tests and implementation. Confirm the reported skeleton work is merged before treating this as complete. |
| Critical | [#57 Unit and tool test suites](https://github.com/skyarkitekten/terminal-velocity/issues/57) | 3 h | Build on #58; add tests as agent and tool behavior is introduced. |
| Critical | [#59 Bandit security scanning](https://github.com/skyarkitekten/terminal-velocity/issues/59) | 1 h | Configure alongside Python CI and scan the source delivered by #58. |
| Critical | [#74 Break down #58](https://github.com/skyarkitekten/terminal-velocity/issues/74) | 2 h | Coordinate with #58; use reviewable increments where work remains. |
| High | [#76 v1.0.0 release plan](https://github.com/skyarkitekten/terminal-velocity/issues/76) | 2 h | Do first: establish acceptance criteria and milestones to guide the remaining scope. The issue itself is labeled high priority. |
| High | [#60 Per-environment agent config](https://github.com/skyarkitekten/terminal-velocity/issues/60) | 4 h | Define the schema and environment-specific values before deployments and smoke tests consume them. |
| High | [#62 Post-deploy smoke-test gate](https://github.com/skyarkitekten/terminal-velocity/issues/62) | 4 h | Needs a deployable agent and environment configuration; gate each deployment stage. |
| High | [#61 Evaluation results in PRs](https://github.com/skyarkitekten/terminal-velocity/issues/61) | 3 h | Needs evaluation output to report; sequence after evaluation execution and the deployment/evaluation gates are established. |
| High | [#77 First-agent walkthrough](https://github.com/skyarkitekten/terminal-velocity/issues/77) | 5 h | Validate the end-to-end path after #58, #57, #59, #60, and #62 are usable. |
| Medium | [#63 Repository hygiene](https://github.com/skyarkitekten/terminal-velocity/issues/63) | 2 h | Can proceed in parallel with implementation. |
| Medium | [#64 README architecture and setup](https://github.com/skyarkitekten/terminal-velocity/issues/64) | 3 h | Document the working architecture and setup; coordinate with #77 to avoid duplicating the walkthrough. |
| Medium | [#65 Model-version upgrade playbook](https://github.com/skyarkitekten/terminal-velocity/issues/65) | 3 h | Document the promotion and evaluation process established by the delivery pipeline. |
| Medium | [#66 SLO targets and breach actions](https://github.com/skyarkitekten/terminal-velocity/issues/66) | 3 h | Agree on measures and targets before building the workbook (#67) or continuous evaluation (#70). |
| Medium | [#67 App Insights workbook](https://github.com/skyarkitekten/terminal-velocity/issues/67) | 5 h | Follows #66; visualizes the agreed SLOs and per-version data. |
| Medium | [#75 Document issue dependencies](https://github.com/skyarkitekten/terminal-velocity/issues/75) | 2 h | Can proceed in parallel; record and link the dependency order below in GitHub. |
| Medium | [#78 Local development guide and tooling](https://github.com/skyarkitekten/terminal-velocity/issues/78) | 4 h | Coordinate with #56 and #58 so documented commands match the actual project setup. |
| Low | [#68 Agent-proposed fixes through standard gates](https://github.com/skyarkitekten/terminal-velocity/issues/68) | 1–2 weeks | Requires an operating standard delivery pipeline, evaluation/guardrail gates, and human approval. |
| Low | [#69 Canary attribution and decisions](https://github.com/skyarkitekten/terminal-velocity/issues/69) | 1–2 weeks | Requires per-version telemetry and a production canary path; record keep/rollback decisions. |
| Low | [#70 Continuous evaluation of production traffic](https://github.com/skyarkitekten/terminal-velocity/issues/70) | 1–2 weeks | Requires agreed SLOs (#66), telemetry, and evaluation data. |
| Low | [#71 SLO breach issue automation](https://github.com/skyarkitekten/terminal-velocity/issues/71) | 1–2 weeks | Requires SLOs and production evaluation signals; feeds the improvement loop in #68. |

### Dependencies outside this 20-issue scope

The issue set above does not include all prerequisites in the existing backlog.
In particular, #56 (Python project scaffolding) is a prerequisite for the Python
test/security work; #54 (deployment mechanism) informs #55; and the agent
pipeline/lifecycle work (#9, #15, #17, #28, #55) is needed to deploy an agent and
run #62 and #77. Evaluation execution and its dataset (#11 and #36) are also
needed before #61 can report meaningful results. Treat these as blocking work in
the broader roadmap, not as completed by this plan.

## Phased rollout

| Phase | Target | Work and exit criteria |
| --- | --- | --- |
| 1. Foundation | Weeks 1–2 | Complete or confirm #58; deliver #57 and #59; split remaining skeleton work through #74. Start #76 immediately and agree v1.0.0 acceptance criteria. |
| 2. Delivery readiness | Weeks 2–4 | Complete the broader lifecycle and pipeline prerequisites (#55, #17, #15, #28), then configure #60 and gate deployments with #62. Surface evaluation results through #61 once evaluations produce reportable results. |
| 3. Validation and polish | Weeks 2–5, in parallel | Deliver #77 against the working path. Work on #63, #64, #65, #75, and #78 in parallel. Complete #66 before #67. |
| 4. Continuous improvement | After core release gates | Consider #70 and #71 once production signals and SLOs are available; then build the proposed-fix and canary loop (#68 and #69) through the same gates with human approval. |

The 4–5 week v1.0.0 target is credible only if the broader pipeline prerequisites
are staffed in parallel and the release criteria in #76 are agreed early.
Foundation work is estimated at about 8 person-hours; the high-priority
delivery-readiness work at about 16 person-hours. Documentation and observability
can progress alongside engineering, while the low-priority automation is a
separate multi-week effort after the core release.

## Critical path and parallel work

```text
#56 Python setup
  → #58 package skeleton
  → #57 tests + #59 security scan
  → #55 lifecycle scripts and #17 agent CI
  → #60 environment config
  → #15 reusable deploy workflow → #28 dev-to-prod CD
  → #62 smoke-test gate
  → #77 end-to-end walkthrough

#76 release criteria: start in Phase 1
#61 evaluation reporting: after evaluation execution is available
#66 SLO targets → #67 workbook
#63, #64, #65, #75, #78: parallel documentation / contributor work
After core gates: #70, #71, #68, #69
```

Dependencies shown are sequencing recommendations; add or confirm the
corresponding blocked-by links on GitHub as part of #75.

## Decisions and next actions

1. Agree on the v1.0.0 acceptance criteria and milestone through #76 before
   treating the target date as a commitment.
2. Confirm the #58 implementation update and finish the remaining #56, #57, and
   #59 foundation work; use #74 to keep any follow-up changes reviewable.
3. Assign owners for the lifecycle and agent-pipeline prerequisites, followed by
   #60, #62, and #61.
4. Run #77 as an end-to-end validation after the pipeline is usable; complete
   #63–#67 and #78 in parallel where dependencies allow.
5. Use #75 to create GitHub dependency links and milestones, then start Phase 1.

The project currently documents a **dev → prod** topology with no staging
environment. Issue #77 mentions dev → staging → prod; align its walkthrough with
the documented topology unless the environment decision in ADR #52 changes.

The autonomous-improvement issues must not bypass production safeguards:
candidate changes go through the normal checks, and production promotion requires
human approval.
