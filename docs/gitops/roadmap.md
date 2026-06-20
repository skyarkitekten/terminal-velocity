# GitOps Roadmap & Gap Analysis

> Outline + bullets. Scope: **IaC + CI/CD only.** Voice and prose to be smoothed
> later. Reviewed against the four Microsoft Foundry reference posts (P1 primary,
> P2–P4 supporting).

## 1. Where we are today

### Built (infra GitOps loop is real)

- **Modular Terraform** under `infra/modules/*` composed by a `platform` stack —
  ahead of P4's flat layout; matches P4's "modular design" best practice.
- **New Foundry resource model** via the AVM `avm-ptn-aiml-ai-foundry` pattern
  (`azurerm_cognitive_account` kind `AIServices` + project), not the legacy Hub
  model — the thing all four posts insist on.
- **Keyless OIDC** end to end: `azure/login` + `ARM_USE_OIDC`, value-free
  `backend.tf`, per-env state key `<env>/terminal-velocity.tfstate`.
- **Infra CI/CD**: `infra-ci.yml` (plan-only on PR) → `infra-cd.yml` (apply dev →
  prod, prod gated by required reviewer) via reusable `terraform.yml`.
- **Observability substrate**: Log Analytics + Application Insights wired with
  diagnostics from day one.
- **Least-privilege identity**: agent-runtime UAMI + CI deploy principal, roles
  by stable definition ID.

### Not yet built (the agent GitOps loop)

Everything past `terraform apply` — the entire P1/P2/P3 core — is still issues,
not code. See gaps below.

## 2. Gap analysis vs. the reference posts

Legend: ✅ done · 🟡 partial/captured as issue · ❌ missing (and whether tracked).

### Infrastructure as Code

| Capability | Source | Status | Notes |
| --- | --- | --- | --- |
| New-model Foundry account + project | P1, P4 | ✅ | via AVM module |
| Modular, env-parameterized Terraform | P4 | ✅ | modules + `platform` stack |
| Remote state, OIDC, per-env key | P1–P4 | ✅ | |
| Model deployment in Terraform | P4 | ✅ | `gpt-4.1-mini` GlobalStandard |
| Runtime + CI identity & RBAC | P4 | ✅ | `identity_rbac` module |
| **Azure Container Registry (ACR)** | P1, P2 | 🟡 #35 | Hosted-agent images need an ACR (`admin_enabled=false`) + `AcrPull` to the project identity. No ACR module exists yet. |
| **`terraform plan` as sticky PR comment** | P1, P4 | 🟡 #2 | Captured; not implemented. Posts treat the plan as the review artifact. |
| **Drift detection job** (`plan -refresh-only` on a schedule) | P4 | 🟡 #44 | Recommended by P4; nothing scheduled yet. |
| Agent definition in Terraform | P1, P4 | n/a | Posts explicitly say agent versions are **not** Terraform's job — keep them in the agent pipeline (script/SDK). |
| Private networking (VNet/PE) | P4 | 🟡 | `ai_foundry` exposes `create_private_endpoints`; deferred, fine for skeleton. |

### CI/CD — agent delivery

| Capability | Source | Status | Notes |
| --- | --- | --- | --- |
| Epic: agent delivery pipeline | P1–P3 | 🟡 #9 | umbrella |
| Agent CI (lint/type/build) on `src/**` PRs | P2, P3 | 🟡 #17 | add `ruff`, type-check, `agent.yaml` schema validation |
| Reusable agent-deploy workflow (OIDC) | P1–P3 | 🟡 #15 | mirror `terraform.yml` shape |
| CD dev → prod + approval gate | P1–P3 | 🟡 #28 | mirror `infra-cd.yml`; eval gate stubbed |
| Version/tagging + deployment outputs | P1 | 🟡 #27 | should pin by **image digest**, emit `deployment-manifest.json` (agent id, version, digest, source SHA, eval-dataset hash) |
| **Build once, promote same artifact** | P1, P3 | 🟡 #39 | "promote the digest, never rebuild per env" as an explicit pipeline rule. |
| **Tested rollback workflow** | P1–P3 | 🟡 #39 | Keep last 2 known-good versions live; rollback = switch active version / traffic weight; test before an incident. |
| **CODEOWNERS** for `src/prompts|agents`, `infra/**` | P3 | 🟡 #37 | Enforce review by path. |
| **Prompt-based agent path** (no build) | P2 | 🟡 #43 | Decision: ship **both** hosted + prompt-based agents. Prompt-based = versioned YAML/config bundle. |
| **Model-version upgrade playbook** | P1 | ❌ **untracked** | PR changes only the model deployment name/version → full eval at 0% traffic → canary. Doc-only follow-up. |
| Two environments (dev/prod) | P1, P2 | ✅ **decided** | This demo uses **dev → prod** (no staging); lean on canary in prod. |

### Evaluations, guardrails, observability (hill-climbing)

| Capability | Source | Status | Notes |
| --- | --- | --- | --- |
| Eval suite as blocking CI gate | P1, P2 | 🟡 #11 | concrete thresholds exist (P2): hallucination, task-completion, groundedness, p95 latency, policy violations |
| Golden eval dataset as first-class artifact | P1, P2 | 🟡 #36 | 20–50 JSONL scenarios + graders; pin grader model |
| Safety guardrails / content safety / policy gate | P2, P4 | 🟡 #42 | "0 policy violations" hard gate |
| **Red teaming** (adversarial/jailbreak suite) | (extends posts) | 🟡 #38 | Scheduled adversarial eval; PyRIT / AI Red Teaming Agent |
| SLOs + dashboards | P1, P3 | 🟡 #13 | latency / task-success / cost; App Insights workbooks |
| Continuous eval on sampled prod traffic | P1, P2 | 🟡 #13 | scheduled offline grading + drift detector |
| Per-version telemetry (version id/digest on spans) | P1 | 🟡 #41 | Essential during traffic splits. |
| SLO-breach → issue → agent-assisted fix | P1 | 🟡 #10 | the philosophy's semi-automated loop |

## 3. Proposed sequencing (hill-climbing steps)

Each step is the smallest change that leaves both loops provably green before the
next. Mirrors P1's maturity ladder, scoped to GitOps.

1. **Close the IaC gaps** — add ACR module (+ `AcrPull`), `plan` PR-comment (#2),
   scheduled drift detection, CODEOWNERS. *(unblocks the container path; cheap.)*
2. **Stand up the agent pipeline skeleton (#9)** — `agent-ci.yml` (#17) → reusable
   `agent-deploy.yml` (#15) → `agent-cd.yml` dev→prod + approval (#28), validated
   with a placeholder agent. Eval gate is a **no-op stub** here.
3. **Versioning & rollback (#27 + new)** — digest-pinned versions,
   `deployment-manifest.json`, build-once/promote-same, tested rollback.
4. **Evals advisory → blocking (#11)** — golden dataset + graders; run advisory
   first, then flip to a blocking gate with P2's thresholds.
5. **Guardrails + red teaming (#11)** — content-safety/policy hard gate (0
   violations); scheduled adversarial red-team eval.
6. **SLOs + continuous eval (#13)** — per-version telemetry, workbooks, scheduled
   prod-traffic grading with drift alerts.
7. **Semi-automated hill-climbing (#10)** — SLO breach auto-files an issue with
   traces/failing evals, assigns an agent to propose a fix, human approves
   promotion. "Only step downhill (rollback) with good reason."

## 4. Decisions & open questions

**Decided**
- **Environments** — **dev → prod** (2 environments) for this demo. No staging;
  rely on canary in prod.
- **Agent types** — ship **both** hosted (container + ACR, #35/#9) and
  prompt-based (YAML/config bundle, #43) agents.
- **Self-hosting** — tracked as a spike (#40); out of scope for the initial demo.

**Still open**
- **azd vs. Foundry SDK script** for version create/promote — #15/#27 assume a
  script (`deploy_agent_version.py`); confirm.
- **Toolboxes (P3)** — adopt versioned, centrally-governed tool bundles now or
  later? Affects how `src/tools` is wired.
- **Model-version upgrade playbook** — capture as a doc/runbook (untracked).
