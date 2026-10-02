# Terminal Velocity: Issue Review, Prioritization & Improvement Plan

**Review Date**: 2026-10-02  
**Reviewer**: Copilot  
**Status**: Ready for implementation  

---

## Overview

Terminal Velocity currently has **20 open issues** (15 original + 5 newly proposed) across four tiers:
1. **CRITICAL**: Foundation architecture (#58, #57, #59)
2. **HIGH**: CI/CD infrastructure (#60, #62, #61, #77)
3. **MEDIUM**: Documentation & observability (#63–#67, #75, #78)
4. **LOW**: Hill-climbing autonomous improvements (#68–#71, #76)

This document presents:
- Prioritized issue backlog with sequencing
- Newly proposed issues addressing gaps
- Effort estimates and dependencies
- Recommended rollout phases

---

## Priority Tiers

### 🔴 CRITICAL (Do First)

Must complete before higher-tier work:

| # | Issue | Effort | Notes |
|---|-------|--------|-------|
| **58** | Create `src/agents/` and `src/tools/` package skeleton | M | Blocks all agent development. Split into sub-PRs (#74). |
| **57** | pytest unit + tool test suites | M | Foundation for validation. Start after #58 structure. |
| **59** | CI: bandit security scanning on Python source | S | Security gate required before production. |
| **74** | Break down: Package skeleton (#58) → smaller PRs | S | **NEW**: Improves velocity by enabling parallel review. |

**Timeline**: Weeks 1–2  
**Exit Criteria**: Package structure exists, pytest framework configured, security scanning integrated into CI.

---

### 🟠 HIGH (Unblock Production Readiness)

Depend on CRITICAL tier; unblock observability:

| # | Issue | Effort | Depends On | Notes |
|---|-------|--------|-----------|-------|
| **60** | Per-environment agent config + JSON schema | M | #58 | Enables multi-env deployments. |
| **62** | Post-deploy smoke test gate | M | #60 | Catches regressions early. |
| **61** | Surface eval results as PR comment + job summary | S | #62 | Developer feedback loop. |
| **77** | First-agent walkthrough (end-to-end guide) | L | #58, #57, #59 | **NEW**: Validates infrastructure; tangible success demo. |

**Timeline**: Weeks 3–4  
**Exit Criteria**: Agent configs deployed to dev/staging/prod; smoke tests green; walkthrough documented and working.

---

### 🟡 MEDIUM (Polish & Observability)

Low-risk documentation; observability foundation:

| # | Issue | Effort | Depends On | Notes |
|---|-------|--------|-----------|-------|
| **63** | Repo hygiene: LICENSE, SECURITY.md, PR templates | S | None | Enables external contributions. Do early. |
| **64** | Docs: README Architecture & Getting Started | M | #63 | Improves onboarding. |
| **65** | Docs: model-version upgrade playbook | M | None | Operational reference. |
| **66** | SLOs: define targets, windows, breach actions | M | None | Foundation for monitoring. |
| **67** | App Insights workbook for SLOs | M | #66 | Monitoring dashboard. |
| **75** | Link & document CI/CD dependencies | S | None | **NEW**: Clarifies sequencing for team. |
| **78** | DevEx: Local development setup guide | M | #58 | **NEW**: Accelerates contributor onboarding. |

**Timeline**: Weeks 2–5 (parallel with HIGH tier)  
**Exit Criteria**: Repository professionally maintained; SLO definitions written; workbook operational; contributor guide clear.

---

### 💡 LOW (Post-v1.0.0)

Autonomous improvement loops; start only after core stable:

| # | Issue | Effort | Depends On | Notes |
|---|-------|--------|-----------|-------|
| **68** | Hill-climbing: agent auto-assignment + PR fix | L | #58–#61 | Auto-proposes fixes via PR. |
| **69** | Canary traffic split + delta attribution | L | #67, #66 | A/B test agents; measure impact. |
| **70** | Continuous evaluation: drift detection + grading | L | #61 | Detect model degradation. |
| **71** | SLO breach auto-files issue with traces | L | #67, #70 | Auto-incident creation. |
| **76** | v1.0.0 Release Plan: acceptance criteria + milestones | M | None | **NEW**: North star for prioritization. |

**Timeline**: Post-v1.0.0 (Weeks 6+)  
**Exit Criteria**: Agents autonomously improve without manual intervention.

---

## Newly Proposed Issues

### #74: Break Down Package Skeleton (#58) into Smaller PRs
**Why**: #58 is a large task; splitting reduces review burden and enables parallel work.

**Suggested breakdown**:
1. Directory structure + `__init__.py` files
2. Type stubs + docstring templates
3. Update `pyproject.toml` + entry points
4. Agent/tool template generators

**Impact**: Each PR ships independently; faster iteration.

---

### #75: Link & Document CI/CD Dependencies
**Why**: Issues #60, #62, #61, #66, #67 have implicit sequencing; making it explicit clarifies team priorities.

**Deliverable**: Update each issue description with "Depends on X" and "Unblocks Y"; create visual dependency diagram in README.

**Impact**: Clearer what to start when; fewer blocked surprises.

---

### #76: v1.0.0 Release Plan
**Why**: Project roadmap lacks explicit acceptance criteria and milestones. Currently: foundation → CI/CD → observability → hill-climbing, but no "done" definition.

**Deliverable**: Define v1.0.0 success (what must ship), map issues to milestones (foundation / alpha / beta / v1.0.0), create GitHub milestone with target date.

**Impact**: Team alignment on north star; easier tradeoff decisions.

---

### #77: First-Agent Walkthrough
**Why**: Foundation work (#58–#59) is abstract; new users don't know how to use it. Walkthrough makes it concrete.

**Deliverable**: Step-by-step guide:
- Write "Hello World" agent
- Unit test it
- Deploy to dev/staging/prod
- Troubleshoot common issues

**Impact**: Validates infrastructure; serves as end-to-end integration test; removes onboarding friction.

---

### #78: DevEx Local Development Setup Guide
**Why**: Contributors need clear setup instructions; reduce friction.

**Deliverable**:
- Virtual environment (Python >= 3.14) instructions
- Pre-commit hooks (linting, type-checking, security)
- IDE configuration (VS Code, PyCharm)
- Hot reload / watch mode
- Makefile for common tasks

**Impact**: Faster contributor onboarding; consistent dev experience.

---

## Sequencing by Phase

### Phase 1: Foundation (Weeks 1–2)
```
Parallel:
  ├── 58: Package skeleton
  │   └── 74: Sub-PRs for #58 (improve velocity)
  ├── 57: pytest suites (start after #58 structure)
  ├── 59: bandit security
  └── 63: Repo hygiene (low-risk, high-visibility)

Then:
  └── 64: README Architecture section
```

**Outcome**: Agent development infrastructure ready.

---

### Phase 2: CI/CD & Validation (Weeks 3–4)
```
Sequential (each unblocks next):
  ├── 60: Per-environment config
  ├── 62: Post-deploy smoke tests
  ├── 61: PR comment results
  └── 77: First-agent walkthrough (validates all)

Parallel:
  ├── 65: Upgrade playbook
  ├── 75: Dependency documentation
  └── 78: DevEx setup guide
```

**Outcome**: Multi-environment deployments + validation gates working.

---

### Phase 3: Observability (Week 5)
```
Sequential:
  ├── 66: SLO targets & definitions
  └── 67: App Insights workbook
```

**Outcome**: Monitoring infrastructure operational.

---

### Phase 4+: Hill-Climbing (Post-v1.0.0)
```
68, 69, 70, 71 only after Phases 1–3 complete
```

**Outcome**: Autonomous agent improvement loops.

---

## Effort Estimates

| Size | Duration | Examples |
|------|----------|----------|
| **S** (Small) | 2–4 hours | #59 (bandit), #75 (docs), #63 (hygiene) |
| **M** (Medium) | 4–8 hours | #58 (skeleton), #60 (config), #66 (SLOs) |
| **L** (Large) | 1–2 weeks | #77 (walkthrough), #67 (workbook), hill-climbing |

**Total Effort**:
- Foundation (Critical) → 8 hours
- CI/CD (High) → 16 hours + 1–2 week walkthrough
- Docs & observability (Medium) → 16 hours
- Hill-climbing (Low) → 3–4 weeks

**v1.0.0 Target**: ~4–5 weeks

---

## Critical Path

```
Start: 58 → 57 → 59 → 60 → 62 → 61 → 77 ✓ (8–9 weeks including walk-through)
Parallel: 63 → 64, 75, 78, 66 → 67
After v1.0.0: 68, 69, 70, 71
```

**Key constraint**: #77 walkthrough validates the entire stack; don't ship v1.0.0 without it.

---

## Next Steps

1. **Assign #76** (v1.0.0 Release Plan) → Product owner defines milestones
2. **Assign #58 + #74** → Lead engineer starts foundation
3. **Assign #57, #59** → QA/security, start after #58
4. **Assign #63, #64** → Technical writer, parallel with engineering
5. **Update GitHub** → Add issue links, dependency docs, milestones
6. **Start Phase 1** → Begin work on #58

---

## Recommendation

**Begin immediately with CRITICAL tier (#58 → #57 → #59).** All other work is blocked on foundation. Use #74 sub-PR strategy to maintain velocity through code review. Once foundation is stable, parallelize HIGH and MEDIUM tiers in Phases 2–3.

**Target**: v1.0.0 within 4–5 weeks.

---

**Document Status**: Ready for team review  
**Last Updated**: 2026-10-02  
