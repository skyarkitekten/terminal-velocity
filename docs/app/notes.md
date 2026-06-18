# Feature Set

## 1. Base product (stable substrate — the part _not_ in the loop)

These exist so the agents have something to operate; they don't change during a demo.

- **Parcels** — size, weight, SLA tier (Same-day / Next-day / Economy), destination, optional delivery window.
- **Fleet** — vehicles with capacity + shift hours, current location.
- **Terminals** — sorting depots (the pun earns its keep), each owning a set of zones.
- **Assignment + sequencing** — the core agent job: parcel → route → stop order.

SLA tiers are the load-bearing choice here: they make the objective _multi-dimensional_ (speed vs. cost vs. miles), which is what gives hill-climbing a real surface to climb instead of a single scalar.

## 2. Policy levers (the agent-writable plane — prompts + tool selection)

This is where steps happen. Each lever has to be tunable via prompt or tool choice, or it doesn't belong in your policy plane.

- **Tool selection:** simple router vs. traffic-aware router; call geocode-validate or not; invoke a consolidation optimizer or not; call a re-attempt predictor before retrying. A hill-climbing step = _"start calling traffic-aware router for Same-day parcels."_
- **Prompt tuning:** how the dispatch agent weighs priority tradeoffs, its risk tolerance in sequencing, how aggressively it consolidates.
- **Consolidation / batching** — combine parcels to a shared zone. A juicy lever: directly moves miles-per-delivery and cost, so it shows up loud in telemetry.

## 3. Drift + exogenous sources (what makes the loops run)

Split deliberately, because the split _is_ the attribution problem.

- **Inner-loop drift (endogenous — agent should reconcile):** dynamic urgent-parcel injection mid-day; failed delivery / recipient-not-home (→ re-attempt rate); address ambiguity (→ tests whether the tool-selection policy calls geocode-validate).
- **Exogenous noise (the "world" — agent should _not_ be blamed for):** weather and traffic events. This is the snowstorm. Its only job in the feature set is to exist so canary attribution has something to separate policy-delta from. Without it, you can't demo "my policy vs. the world."

**Objective function it produces:** SLA hit rate (per tier), cost per parcel, re-attempt rate, miles per delivery. A policy diff is a step; promote → measure attributed delta → keep or roll back.

The elegance check: every feature above is justified by a layer it feeds. Address ambiguity exists _because_ tool selection is in the policy plane. Weather exists _because_ attribution is load-bearing. SLA tiers exist _because_ a flat objective has no hill. That's the Picnic discipline — nothing in the domain that isn't pulling architectural weight.

## 4. Agent topology

A fleet turns the single clean attribution problem into a credit-assignment problem, and that's the thing the orchestration story has to solve — not "how do the agents talk" but "when SLA drops, which agent's step did it." That's the architectural center of gravity.

The fleet (each owns a slice of the policy plane):

1. **Routing agent** — assignment + sequencing; tool lever is simple vs. traffic-aware router.
2. **Consolidation agent** — batching parcels to shared zones.
3. **Re-attempt agent** — failed-delivery prediction + retry timing.
4. **Orchestrator** — coordinates them at runtime and (the important part) owns the shared objective and serializes promotion. Not a climber itself — the referee.

## 5. Potential Pitfalls

1. **Concurrent steps destroy attribution.** If routing and consolidation both promote into the same canary window, the telemetry delta can't be assigned to either. Cleanest fix: one step in flight across the whole fleet — the orchestrator serializes promotions so every canary measures exactly one agent's diff against control. This keeps your "previous only" rollback decision intact: previous = last fleet-good state, rollback reverts the single in-flight step.

2. **Interaction effects = fleet-level local optima.** Consolidation and routing are coupled — a step that's uphill for consolidation in isolation can be downhill for the system because it hands routing a worse problem. So evals must score the system objective, not per-agent local objectives. If each agent climbs its own hill, the fleet walks downhill with all-green local evals. This is the multi-agent version of the Goodhart caveat, and it's sharper here.
3. **The escalation guard goes per-slice.** Your "N consecutive rollbacks → gate plane" guard now attributes per agent: if routing keeps tripping but consolidation is fine, you escalate routing's slice, not the fleet. More precise, and it tells the human exactly which agent's thresholds may no longer describe reality.

**What this does to the orchestrator:** it's doing double duty — runtime coordination and promotion serialization. That unification is actually the cleanest way to present "orchestration" in the arch: the same component that routes work between agents is the one that enforces one-step-in-flight on the climb. Orchestration isn't a separate concern bolted on; it's what makes multi-agent hill-climbing attributable at all.

This is an ambitious demo, so the orchestration story has to be tight to keep it legible:

- **Serialized promotion (one canary at a time, fleet-wide).**Attribution stays trivial, the climb is slower, the demo is legible and shippable. The orchestrator is a simple lock.

- **Partitioned/parallel canaries** (split traffic by zone or terminal so multiple agents can canary their steps simultaneously on disjoint slices). The climb is faster and it's a far more impressive orchestration story — but now attribution has to account for slice heterogeneity (a snowstorm in one partition isn't in another), which compounds the canary math considerably.
