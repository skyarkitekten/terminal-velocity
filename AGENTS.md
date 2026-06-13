# AGENTS.md

Guidance for AI coding agents working in **Terminal Velocity** — a reference
implementation that applies GitOps principles to building and deploying agents to
Microsoft Foundry, using package delivery as the business domain.

Before doing any work, walk through the following steps in order.

## 1. Determine if an appropriate agent is already defined

Check whether a specialized agent already exists for the task before doing the
work yourself.

- Look for defined agents (custom chat modes, `*.agent.md` files, or subagents
  registered for this workspace).
- Match the user's request against each agent's description and intended domain.
- If a suitable agent exists, delegate to it (invoke the subagent) rather than
  reimplementing its behavior.
- If no agent fits, proceed with the steps below as the default agent.

## 2. Determine the intention

Establish what the user actually wants before acting.

- Identify the goal: are they asking a question, requesting a change, debugging,
  reviewing, or planning?
- Infer the most useful likely action when the request is ambiguous, then use
  tools to confirm missing details instead of guessing.
- Clarify only when genuinely blocked — prefer discovery via the codebase.
- Restate the intended outcome to yourself before making changes.

## 3. Decide if planning or reasoning is required

Match effort to complexity.

- **Simple, single-step tasks** (read a file, answer a question, make one small
  edit): act directly, no planning overhead.
- **Multi-step or cross-cutting work** (new agent, new tool, infra changes,
  deployment flows): create a plan and track it as a todo list before editing.
- Reason explicitly when a task touches GitOps state, deployment, or
  infrastructure, since these are higher-risk and harder to reverse.
- Confirm before destructive or hard-to-reverse actions (pushing, force-resetting,
  deleting branches, modifying shared infrastructure).

## 4. Understand the project layout

Orient yourself in the repository before writing code.

```
AGENTS.md          Agent guidance (this file)
README.md          Project overview and philosophy
pyproject.toml     Python project metadata (requires Python >= 3.14)
docs/              Project documentation
infra/             Infrastructure-as-code and deployment definitions
src/
  agents/          Agent implementations deployed to Microsoft Foundry
  tools/           Tools that agents can call
```

Key facts:

- **Domain**: package delivery (things distributed "from a terminal").
- **Approach**: GitOps — Git is the single source of truth for infrastructure,
  application code, configuration, and deployment. Changes flow through Git and
  trigger automated deployments.
- **Target platform**: Microsoft Foundry.
- **Language/runtime**: Python `>= 3.14`.
- New agents belong in `src/agents/`; tools they invoke belong in `src/tools/`.
- Infrastructure changes belong in `infra/`; keep them declarative and auditable.

## Working principles

- Make changes directly rather than only suggesting them; implement what is asked
  and what is clearly necessary, nothing more.
- Read files before modifying them and follow existing conventions.
- Keep the desired system state expressed declaratively in Git.
- Don't add features, refactors, comments, or abstractions beyond the request.
