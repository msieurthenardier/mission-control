# Sorties

A **sortie** is Flight Control's unit for work that needs a flight but not a mission: one outcome a user would notice, one cluster of design decisions, one flight. It is a flight with no parent mission.

## Why Sorties Exist

Squawks closed the gap below the mission for defects and routine upkeep. They left a second gap just above them. A small feature — add an option to an existing command, change one behavior a user relies on — fails the squawk gate honestly. It adds behavior, it usually changes an interface someone calls, and it has a design decision or two worth making on purpose. A mission, meanwhile, costs a full outcome interview, a separate mission artifact, and a mission debrief on top of the flight's own. For one flight's worth of work, that ceremony is larger than the planning it wraps.

So in-between work went one of two ways: squeezed through the squawk gate, where its design decisions went unreviewed, or inflated into a single-flight mission that cost more to plan than to build. The sortie is the proportional vehicle.

## The Aviation Model

A sortie is a single flight by a single aircraft — one takeoff, one objective, one landing. It is not a campaign. It still gets a full preflight, a flight plan, and a debrief; what it does not have is an operation around it.

That maps directly: a sortie keeps every part of the flight — design review, leg breakdown, independent code review, debrief — and drops the mission above it.

## Qualification

Something is a sortie only if **all four** hold:

1. **One self-contained outcome** — behavior a user would notice as new or changed, statable in one sentence, and not a step toward a larger outcome. If other planned work depends on it, it belongs to that work's mission.
2. **One cluster of design decisions** — open questions that can be settled in a single planning conversation
3. **Fits one flight** — typically 1-2 legs plus an optional HAT (human acceptance test) leg. Beyond that is a signal to re-check criterion 2, not a hard limit.
4. **No new subsystem and no cross-cutting architecture change**

Where it sits between its neighbours:

| | Squawk | Sortie | Mission |
|---|---|---|---|
| Design decisions | None | One cluster | Several, or one that shapes later work |
| Adds behavior | No | Yes | Yes |
| Shared interface, schema, security surface | Not allowed | Allowed, as a design decision | Allowed |
| Artifacts | Squawk | Flight with a charter | Mission, flights |
| Review | Diff-scoped sign-off | Full flight review | Full flight review per flight |
| Debrief | None | Flight debrief | Flight debriefs and a mission debrief |

**The difference from a squawk is design, not size.** A sortie gets the full flight treatment — Architect design review, independent code review, a debrief — and that is what lets it touch surfaces a squawk may not.

**The gate matters more than the criteria.** A sortie that discovers a second, independent cluster of decisions during flight design is escalated to a mission and becomes that mission's first flight. Once in flight, it lands or aborts with what its charter covers, and the discovered work becomes a new sortie or mission. It is never widened in place. Without that rule the short path becomes a way around mission planning, one "small feature" at a time.

## Anatomy

A sortie is a flight artifact, stored per `ARTIFACTS.md` (default `sorties/{NN}-{slug}/`), with the same flight log, briefing, debrief, and legs as any flight, and the same lifecycle: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`).

The one addition is the **charter**, which takes the place of the mission link. It carries the part of a mission a flight still needs:

- **Outcome** — one sentence, in human terms
- **Why now** — what prompted it
- **Success criteria** — 2-4, observable and binary
- **Constraints** — if any

A charter is a few lines. One that needs stakeholders, a context essay, or more than four criteria is the qualification gate telling you it is a mission.

## Lifecycle of a Sortie

| Step | Skill | What happens |
|------|-------|--------------|
| Plan | `/mission-control:sortie {description}` | Qualify against the gate, agree the charter (the phase gate), then run the flight skill's design phases with the charter standing in for the mission. Re-check the gate against the designed flight before marking it `ready`. |
| Execute | `/mission-control:agentic-workflow sortie {NN}` | Exactly as any flight: leg design, implementation, one review and one commit at the end. No mission to check off at landing. |
| Debrief | `/mission-control:flight-debrief sortie {NN}` | The sortie's only debrief. Also assesses the charter's criteria and whether a sortie was the right vehicle. |

## Around the Rest of the Methodology

**Squawks.** A squawk that fails its gate because it adds behavior, touches an interface, or needs one design call usually escalates to a sortie.

**Missions.** The mission skill offers a sortie when the work it hears is sortie-sized. A single-flight mission is still right when the outcome needs stakeholder framing or room to grow.

**Routine maintenance.** Inspections run at mission boundaries. A project running only sorties never reaches one, so the sortie debrief recommends `/mission-control:routine-maintenance` once three sorties have completed since the last inspection with no mission in between. Recommend only.

**Service reports.** When a sweep measures whether a trend spans at least two missions, a sortie counts as its own mission. Its flight debrief is its only debrief, so nothing restates it. A sortie escalated during planning is corroborating evidence, like an escalated squawk — the escalation marks a place the methodology mis-sorted the work.

## What Sorties Are Not

**Not a small mission.** There is no mission artifact and no mission debrief. If you find yourself wanting them, plan a mission.

**Not a bundle.** Two unrelated small features are two sorties. A merged record cannot be individually escalated, aborted, or debriefed.

**Not a shortcut around review.** A sortie skips mission ceremony, not flight rigor.

## See Also

- [Squawks](squawks.md) — the vehicle below: fixes and upkeep with no design decisions
- [Missions](missions.md) — the vehicle above: outcomes that need more than one flight's planning
- [Flights](flights.md) — the specification a sortie is
- [Workflow](workflow.md) — end-to-end flow from mission to completion
