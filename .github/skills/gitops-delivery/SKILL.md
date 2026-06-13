---
name: gitops-delivery
description: "Deliver infrastructure and agent changes the GitOps way: PR-driven changes that trigger automated, auditable deployments via GitHub Actions using OIDC to Azure. Use when building or reviewing CI/CD workflows, wiring keyless cloud auth, configuring environments and required checks, or promoting changes across environments."
argument-hint: "Describe the pipeline, environment, or promotion flow you need."
---

# GitOps Delivery

Git is the single source of truth. Changes flow through pull requests and trigger
automated deployment; the system converges to the state described in the repo
instead of being changed imperatively.

## When to Use
- Authoring or reviewing GitHub Actions CI/CD for `infra/` or agents.
- Setting up keyless cloud auth (OIDC → Azure) instead of long-lived secrets.
- Configuring environments, required checks, and branch protection.
- Designing how changes promote across environments (e.g. dev → prod).

## Principles
- **Declarative**: the desired state lives in Git; pipelines reconcile to it.
- **PR-driven**: every change is a pull request with plan/diff visible for review.
- **Keyless**: authenticate to Azure with OIDC federated credentials and a
  managed identity — no stored cloud secrets.
- **Least privilege**: scope workflow `permissions` and cloud RBAC to the minimum.
- **Auditable & reversible**: prefer convergence and rollback-via-Git over
  out-of-band fixes.

## Procedure
1. **Map the flow.** Define triggers (PR vs. push to default branch), the target
   environment(s), and what each stage does (plan on PR, apply on merge).
2. **Wire OIDC.** Configure a federated credential on an Azure identity and use
   `azure/login` with `permissions: id-token: write`. No client secrets.
3. **Plan on PR.** On pull requests run `fmt`/`validate`/`plan` and post the plan
   for review. Do not apply from a PR.
4. **Apply on merge.** Gate `apply` behind a protected GitHub Environment with
   required reviewers; apply only after merge to the default branch.
5. **Promote.** Move changes across environments through Git (merge/promotion),
   reusing workflows; never hand-edit a higher environment.
6. **Protect.** Set branch protection and required status checks so changes can't
   bypass review or a green pipeline.

## Constraints
- Never run destructive or shared-environment operations without explicit
  confirmation.
- Never hardcode secrets in workflows; reference Environment/Actions secrets or
  Key Vault, and prefer OIDC.

## Output
- The workflow YAML and any environment/branch-protection configuration.
- A summary of triggers, gates, and the promotion path.
- Next steps, flagging anything that requires confirmation before it runs.
