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
not code. `src/` currently holds only `pyproject.toml` (with `dependencies = []`);
there are no agents, tools, lifecycle scripts, tests, or agent workflows. See gaps
below.

## 2. Gap analysis vs. the reference posts

Legend: ✅ done · 🟡 partial · ❌ missing and untracked · n/a not applicable
(the posts explicitly place this outside our scope).

Most 🟡 rows carry an issue number; the few without one are deliberate deferrals
recorded here rather than in the backlog. There are currently no ❌ rows.

### Infrastructure as Code

| Capability | Source | Status | Notes |
| --- | --- | --- | --- |
| New-model Foundry account + project | P1, P4 | ✅ | via AVM module |
| Modular, env-parameterized Terraform | P4 | ✅ | modules + `platform` stack |
| Remote state, OIDC, per-env key | P1–P4 | ✅ | |
| Model deployment in Terraform | P4 | ✅ | `gpt-4.1-mini` GlobalStandard |
| Runtime + CI identity & RBAC | P4 | ✅ | `identity_rbac` module |
| **Azure Container Registry (ACR)** | P1, P2 | 🟡 #35 | Hosted-agent images need an ACR (`admin_enabled=false`) + `AcrPull` to the project identity. No ACR module exists yet. |
| **`terraform plan` as sticky PR comment** | P1, P4 | ✅ #2 | PRs review dev and prod plans inline; each environment comment updates in place. |
| **Drift detection job** (`plan -refresh-only` on a schedule) | P4 | 🟡 #44 | Recommended by P4; nothing scheduled yet. |
| Agent definition in Terraform | P1, P4 | n/a | Posts explicitly say agent versions are **not** Terraform's job — keep them in the agent pipeline (script/SDK). |
| Private networking (VNet/PE) | P4 | 🟡 *(no issue)* | `ai_foundry` exposes `create_private_endpoints`; deliberately deferred, fine for skeleton. File an issue if we productionise. |

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
| **Model-version upgrade playbook** | P1 | 🟡 #65 | PR changes only the model deployment name/version → full eval at 0% traffic → canary. Doc-only follow-up. |
| Two environments (dev/prod) | P1, P2 | ✅ **decided**; ADR #52 pending | This demo uses **dev → prod** (no staging); lean on canary in prod. Deviates from P2's recommended dev → test → prod; ADR #52 will record the compensating controls. |
| **Agent lifecycle scripts** (deploy / promote / rollback / inspect) | P1–P3 | 🟡 #55 | The Python CLI surface the workflows call. Owns the deployment manifest; makes build-once/promote-same mechanical. Blocks #15, #27, #28, #39. |
| **Per-environment agent config + schema** | P2 | 🟡 #60 | `config/agent-config.<env>.json` + JSON Schema, validated in CI. Endpoints/model/thresholds per env; no secrets. |
| **Post-deploy smoke test gate** | P1 | 🟡 #62 | Every stage gates on it. Distinct from evals: verifies liveness and wiring, not quality. |
| Python project scaffolding (deps, `ruff`, `pytest`, type-check) | P2 | 🟡 #56 | `dependencies = []` today; blocks #17 and #55. |
| `src/agents/` + `src/tools/` package skeleton | P1–P3 | 🟡 #58 | `AGENTS.md` documents a layout that does not exist on disk. |
| Unit + tool test suites | P2 | 🟡 #57 | P2 runs `pytest tests/unit` and `tests/tools` before the eval gate. |
| **`bandit` Python security scan** | P2 | 🟡 #59 | Sibling of Checkov (#46) for Terraform. |

### Evaluations, guardrails, observability (hill-climbing)

| Capability | Source | Status | Notes |
| --- | --- | --- | --- |
| Eval suite as blocking CI gate | P1, P2 | 🟡 #11 | concrete thresholds exist (P2): hallucination, task-completion, groundedness, p95 latency, policy violations |
| Golden eval dataset as first-class artifact | P1, P2 | 🟡 #36 | 20–50 JSONL scenarios + graders; pin grader model |
| Safety guardrails / content safety / policy gate | P2, P4 | 🟡 #42 | "0 policy violations" hard gate |
| **Red teaming** (adversarial/jailbreak suite) | (extends posts) | 🟡 #38 | Scheduled adversarial eval; PyRIT / AI Red Teaming Agent |
| **Eval results as PR comment / job summary** | P1, P2 | 🟡 #61 | Doc 04 requires reviewers see the diff, incl. delta vs. last-known-good. Agent-side sibling of #2. |
| SLOs defined with targets + breach actions | P1, P3 | 🟡 #66 | Child of #13. No breach signal exists until targets are agreed. |
| SLO dashboards / workbooks | P1, P3 | 🟡 #67 | Child of #13. Workbook as code in `infra/`, sliced by version id. |
| Continuous eval on sampled prod traffic | P1, P2 | 🟡 #70 | Child of #13. Scheduled offline grading + drift detector vs. last-known-good. |
| Per-version telemetry (version id/digest on spans) | P1 | 🟡 #41 | Essential during traffic splits. |
| SLO-breach → auto-filed issue | P1 | 🟡 #71 | Child of #10. Issue carries version id, digest, source SHA, traces, eval diffs. |
| Agent-assisted fix via PR through standard gates | P1 | 🟡 #68 | Child of #10. Automation proposes, human disposes; one step in flight. |
| Canary split + delta attribution + recorded decision | P1 | 🟡 #69 | Child of #10. Primary prod risk control given the 2-env topology (#52). |

## 3. Proposed sequencing (hill-climbing steps)

Each step is the smallest change that leaves both loops provably green before the
next. Mirrors P1's maturity ladder, scoped to GitOps.

0. **Record the blocking decisions** — three ADRs that everything downstream
   depends on: agent deployment mechanism (#54), environment topology (#52), and
   toolbox strategy (#53). #54 in particular blocks the lifecycle scripts and
   therefore the whole agent pipeline.
1. **Close the IaC gaps** — add ACR module (+ `AcrPull`), `plan` PR-comment (#2),
   scheduled drift detection (#44), CODEOWNERS (#37). *(unblocks the container
   path; cheap.)*
2. **Lay the Python foundation** — dependencies + `ruff`/`pytest`/type-check
   config (#56), `src/agents` + `src/tools` skeleton (#58), test suites (#57),
   `bandit` (#59). *(nothing else can be built first.)*
3. **Build the lifecycle scripts (#55)** — deploy, promote/rollback, evals, and
   version inspection behind one deployment manifest. Add per-env agent config
   (#60).
4. **Stand up the agent pipeline skeleton (#9)** — `agent-ci.yml` (#17) → reusable
   `agent-deploy.yml` (#15) → `agent-cd.yml` dev→prod + approval (#28), validated
   with a placeholder agent, gated by a post-deploy smoke test (#62). Eval gate is
   a **no-op stub** here.
5. **Versioning & rollback (#27, #39)** — digest-pinned versions,
   `deployment-manifest.json`, build-once/promote-same, tested rollback.
6. **Evals advisory → blocking (#11)** — golden dataset + graders (#36); run
   advisory first, surface results on the PR (#61), then flip to a blocking gate
   with P2's thresholds.
7. **Guardrails + red teaming** — content-safety/policy hard gate, 0 violations
   (#42); scheduled adversarial red-team eval (#38).
8. **SLOs + continuous eval (#13)** — per-version telemetry (#41), SLO definitions
   (#66), workbooks (#67), scheduled prod-traffic grading with drift alerts (#70).
9. **Semi-automated hill-climbing (#10)** — SLO breach auto-files an issue with
   traces/failing evals (#71), assigns an agent to propose a fix (#68), human
   approves promotion, canary attributes the delta (#69). "Only step downhill
   (rollback) with good reason."

## 4. Decisions & open questions

**Decided**
- **Environments** — **dev → prod** (2 environments) for this demo. No staging;
  rely on canary in prod. Being formalised as an ADR in #52, including where doc
  04's stricter pre-promotion gate runs without a test environment.
- **Agent types** — ship **both** hosted (container + ACR, #35/#9) and
  prompt-based (YAML/config bundle, #43) agents.
- **Self-hosting** — tracked as a spike (#40); out of scope for the initial demo.

**Open — now tracked**
- **azd vs. Foundry SDK script** for version create/promote — ADR #54. Blocks
  #15, #27, #28, #55.
- **Toolboxes (P3)** — versioned central bundles vs. in-repo `src/tools` — ADR
  #53. Determines whether a tool change forces a new agent version.
- **Model-version upgrade playbook** — #65. A runbook rather than an ADR: the
  decision is not in question, only the procedure.

## 5. Reference implementations

Cross-checked against two companion repos alongside the posts:

- [`ericchansen/foundry-agents-lifecycle`](https://github.com/ericchansen/foundry-agents-lifecycle)
  — the closest working implementation of what our docs describe: SDK-based
  lifecycle scripts, per-environment JSON config with a published schema, eval
  dataset, Bicep IaC. Useful shape reference for #55 and #60.
- [`leestott/foundry-cicd`](https://github.com/leestott/foundry-cicd) — the two
  pipeline YAMLs from the post plus repo hygiene (LICENSE, SECURITY.md,
  templates, CODEOWNERS). Treat as a pipeline reference, not an architecture.

Where we are **ahead**: modular Terraform + AVM Foundry pattern and a real infra
GitOps loop — neither reference repo has an equivalent. Where we are **behind**:
the entire agent loop is documentation, which is what steps 2–5 above close.
