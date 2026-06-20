# GitOps for Agents

The primary reference implementation: managing and deploying Microsoft Foundry
agents the GitOps way. Git is the source of truth for infrastructure,
application code, configuration, and deployment. Changes flow through pull
requests and roll out through GitHub Actions using OIDC — no long-lived secrets,
fully auditable.

> Scope note: this section is intentionally narrowed to the **GitOps surface —
> Infrastructure as Code (Terraform) and CI/CD (GitHub Actions)**. Domain
> features (the package-delivery agents) live under [`docs/app`](../app/notes.md).

## Reading order

| Doc | Status | Covers |
| --- | --- | --- |
| [00 — Philosophy](./00-philosophy.md) | written | Hill-climbing, semi-automated improvement, evals/guardrails, human-in-the-loop |
| [01 — Create the infrastructure](./01-create-infrastructure.md) | written | State backend bootstrap, OIDC trust, infra CI/CD loop |
| [02 — Modules](./02-modules.md) | written | Foundry platform modules, backend config, plan/verify |
| [03 — Agent delivery pipeline](./03-agent-delivery-pipeline.md) | outline | Build → version → eval → deploy → promote an agent to Foundry |
| [04 — Evaluations & guardrails](./04-evaluations-and-guardrails.md) | outline | Eval suites, safety guardrails, red teaming as CI gates |
| [05 — SLOs & continuous evaluation](./05-slos-and-continuous-eval.md) | outline | SLOs, dashboards, scheduled eval against prod traffic |
| [06 — Hill-climbing loop](./06-hill-climbing.md) | outline | SLO-breach → issue → agent-assisted fix → human-approved promotion |
| [Roadmap & gap analysis](./roadmap.md) | outline | Where we are vs. the reference posts, sequenced next steps |

## The GitOps loops

Two delivery loops, same shape (PR plans, merge promotes, prod is gated):

- **Infra loop** — `infra/**` changes → `infra-ci.yml` (plan on PR) →
  `infra-cd.yml` (apply dev → prod with approval). **Built today.**
- **Agent loop** — `src/agents|tools/**` changes → `agent-ci.yml`
  (lint/type/build/eval on PR) → `agent-cd.yml` (deploy dev → prod with
  approval). **On the roadmap.**

## Source material

The implementation draws on four Microsoft Foundry posts (see
[roadmap.md](./roadmap.md) for how each maps to our work):

- **Primary** — *DevOps for Microsoft Hosted Agents: From Terraform Apply to
  Production-Grade Agent Delivery.*
- *CI/CD for AI Agents on Microsoft Foundry.*
- *Building and Operating a Microsoft Foundry Hosted Agent with GitOps and
  GitHub Tasks.*
- *Infrastructure as Code for AI: Building and Deploying Microsoft Hosted Agents
  with Terraform.*
