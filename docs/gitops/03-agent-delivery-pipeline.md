# 03 — Agent Delivery Pipeline (CI/CD → Foundry)

> Outline + bullets. Builds the **agent** GitOps loop that mirrors the infra loop
> (`terraform.yml` / `infra-ci` / `infra-cd`). Tracks epic #9 and children
> #17, #15, #28, #27, #21.

## Goal

- Ship a Foundry agent through Git: PR builds + evaluates a candidate, merge
  promotes it **dev → prod** via OIDC, prod gated by a required reviewer.
- Establish the pipe with a **placeholder agent** so it's provably green before
  the real walking-skeleton agent exists.

## The deployment unit: an immutable agent version

- One artifact bundles: container **image digest** (not tag), model deployment
  binding, `agent.yaml` config, env vars, CPU/memory, declared protocols.
- **Build once, promote the same digest** across environments — never rebuild per
  env.
- Platform **deduplicates** identical versions — treat "no new version" as
  success, reuse the version id.

## Repository shape (target)

```
src/
  agents/<name>/
    Dockerfile
    agent.yaml            # name, container, protocols, env, metadata(source_commit)
    src/
    evals/                # dataset.jsonl + graders.yaml (see doc 04)
  tools/
scripts/
  deploy_agent_version.py # build → push by digest → create version → emit manifest
  promote_version.py      # promote a version between environments
  run_evals.py            # see doc 04
.github/workflows/
  agent-ci.yml            # PR gate (#17)
  agent-deploy.yml        # reusable, env-parameterized (#15)
  agent-cd.yml            # dev → prod promotion (#28)
```

## Workflows

### `agent-ci.yml` — PR gate (#17)

- Triggers on PRs touching `src/agents/**` or `src/tools/**`.
- Steps: Python 3.14 setup → install → `ruff` lint → type-check →
  `agent.yaml` schema validation → unit/tool tests.
- Fast, **no Azure credentials** (no deploy). Required check on PRs.
- Later: build candidate at `--traffic 0` and run evals (doc 04).

### `agent-deploy.yml` — reusable deploy (#15)

- `workflow_call`, environment-parameterized (mirror `terraform.yml`).
- OIDC via `azure/login`; no secrets/keys.
- `az acr build` (or `docker build`) → push → capture **digest** →
  Foundry SDK/`azd` create version → smoke-validate.
- Emits `deployment-manifest.json` (agent id, version id, digest, source SHA,
  eval-dataset hash).

### `agent-cd.yml` — promotion (#28)

- On merge to `main`: `deploy-dev` (apply) → `deploy-prod` (`needs` dev,
  `environment: prod` required reviewer).
- Calls `agent-deploy.yml` per environment from the **same manifest/digest**.
- **Eval gate stubbed** here as a no-op; implemented in doc 04 (#11).

## Versioning, outputs & rollback (#27)

- Version derived from Git SHA/tag, stamped on the deployed agent.
- Deployment summary (agent id, version, env, digest) to the job summary.
- Keep the last two known-good versions live; **rollback = switch active
  version / traffic weight**, not a redeploy. Test it before an incident.

## Prerequisites / dependencies

- Foundry infra (epic #14) — account/project/model + CI deploy identity.
- **ACR** to hold agent images (gap — see [roadmap](./roadmap.md)).
- Walking-skeleton agent (epic #12) is delivered *through* this pipe.

## Acceptance (pipe is green)

- [ ] PR on `src/**` runs CI and blocks on failure.
- [ ] Merge deploys a placeholder agent to dev, then prod after approval.
- [ ] A release maps back to a Git SHA via the manifest.
- [ ] Rollback exercised in a non-prod environment.

## Runbook (#21)

- Day-to-day: open PR → review eval/plan output → merge → approve prod.
- Incident: how to roll back, where the manifest/version history lives.
