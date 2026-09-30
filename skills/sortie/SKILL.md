---
name: sortie
description: Plan a sortie — a single standalone flight with no parent mission, for one self-contained outcome with one cluster of design decisions. Use for small features and behavior changes too big for a squawk (they add behavior, touch an interface, or need a design call) but too small to warrant a mission. Qualifies the work, agrees a short charter, then designs the flight.
---

# Sortie

In aviation, a **sortie** is a single flight by a single aircraft — one takeoff, one objective, one landing. It is not a campaign.

A sortie is Flight Control's unit for work that needs a flight but not a mission: one outcome a user would notice, one cluster of design decisions, one flight. It sits between the squawk (no design decisions, nothing new) and the mission (an outcome that needs more than one planning conversation, or is part of a larger initiative).

**A sortie is a flight with no parent mission.** It uses the flight artifact, the flight lifecycle, the flight-design, leg-execution, and flight-debrief crews, and `/mission-control:agentic-workflow` for execution. What it adds is a short **charter** — outcome, why now, success criteria, constraints — carrying the part of a mission a flight still needs. What it drops is the rest of the mission: the full outcome interview, the separate mission artifact, and the mission debrief.

**This skill produces documentation only.** Create and update Flight Control artifacts; never modify source files in the project.

## When to Use

**Plan a sortie** when work meets **all four** of these:

1. **One self-contained outcome** — behavior a user would notice as new or changed, statable in one sentence, and not a step toward a larger outcome. If other planned work depends on it, it belongs to that work's mission.
2. **One cluster of design decisions** — open questions that can be settled in a single planning conversation
3. **Fits one flight** — typically 1-2 legs plus an optional HAT (human acceptance test) leg. More than that is a signal to re-check criterion 2, not a hard limit.
4. **No new subsystem and no cross-cutting architecture change**

If any one fails, it is not a sortie. Say which criterion failed and recommend the right vehicle:

| Instead | When |
|---------|------|
| `/mission-control:squawk` | A single defect or routine servicing item with no design decisions — nothing a user would notice as new |
| `/mission-control:flight` | An active mission already covers this outcome — it is a flight under that mission |
| `/mission-control:mission` | More than one cluster of decisions, a larger initiative, or new architecture |

**The difference from a squawk is design, not size.** A squawk has no design decisions and adds nothing new. A sortie has exactly one cluster of decisions, and may add behavior. Because a sortie gets the full flight treatment — Architect design review, independent code review, a debrief — it **may** change a shared interface, a schema, or a security-sensitive surface, which a squawk may not. Record those as design decisions; they are usually why the work is a sortie rather than a squawk in the first place.

**Lifecycle**: the flight lifecycle — `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`).

## Prerequisites

- Project must be initialized with `/mission-control:init-project` (`.flightops/ARTIFACTS.md` must exist with sortie conventions — run `/mission-control:init-project` to apply migration 011 if missing)

## Invocation

```
/mission-control:sortie {description}     Qualify, charter, and design a new sortie
/mission-control:sortie list              List sorties not yet completed or aborted
/mission-control:sortie escalate {NN}     Promote a sortie to a mission
```

Execution and debrief use the flight skills:

```
/mission-control:agentic-workflow sortie {NN}
/mission-control:flight-debrief sortie {NN}
```

## Context Loading (all verbs)

1. **Read `.flightops/ARTIFACTS.md`** for how this project handles the sortie artifact — its storage location, format, naming/sequence conventions, Git Conventions, and any actions the project defines at create and transition time. Honor these whenever you or a spawned agent creates a sortie or moves one through its lifecycle.
   - **If ARTIFACTS.md has no sortie conventions**: STOP and tell the user to run `/mission-control:init-project` to apply migration 011.

## Verb: Plan

### 1. Qualify

Check the four criteria out loud against the user's description and a quick read of the code it touches. If one fails, say which, recommend the vehicle from the table above, and stop — do not plan a sortie as a workaround for scope.

Also check for existing homes: scan active missions (at the location ARTIFACTS.md defines). If one already covers this outcome, recommend `/mission-control:flight` under it instead.

### 2. Charter

Interview briefly — this replaces the mission interview, so keep it to what is missing. At most:

- **Outcome** — one sentence, in human terms: what is different for the user when this lands?
- **Why now** — what prompted it
- **Success criteria** — 2-4, observable and binary
- **Constraints** — non-negotiable boundaries, if any

Skip any question the user's description already answers. Draft the charter and present it.

**Phase gate: the charter must be explicitly agreed before flight design begins.** This is the sortie's equivalent of the mission gate — a smaller conversation, not a skipped one.

### 3. Create the sortie

Assign the next sortie sequence number by scanning existing sorties at the location ARTIFACTS.md defines, following the project's naming conventions. Persist the sortie artifact with status `planning` and the agreed charter, then perform any create-time handling the project defines. Create the flight log alongside it, per ARTIFACTS.md.

### 4. Design the flight

Follow the phases of `${SKILL_DIR}/../flight/SKILL.md` from Phase 1 step 4 onward, with these substitutions:

- **The charter replaces the parent mission.** Wherever the flight skill reads the mission's outcome, success criteria, or constraints, read the charter. The flight contributes to the charter's criteria, all of them.
- **Existing flights** (Phase 1 step 4): check other open sorties and active missions for overlapping scope or dependencies instead. A dependency in either direction fails criterion 1 — raise it.
- **Prior debriefs** (Phase 1 step 5): read recent flight debriefs across the project — sorties and missions alike — that touch this sortie's likely scope.
- **Artifacts**: the sortie artifact and flight log already exist from step 3; Phase 5 fills them in rather than creating new ones.

Everything else — upstream reconnaissance, code interrogation, the user's open-ended input, the crew interview, behavior-test authoring, the Architect design review, and iteration to approval — runs exactly as it does for any flight.

### 5. Re-check the gate

Flight design is where a sortie discovers what it really is. Before marking it `ready`, re-check criteria 2 and 3 against the designed flight:

- **A second, independent cluster of decisions surfaced** — escalate (see Verb: Escalate). Do not widen the sortie.
- **The legs outgrew the soft limit** — more than two plus an optional HAT. Say so out loud and ask the user: either the leg boundaries can be consolidated, or it is really two flights and should escalate.

### 6. Mark ready

On approval, set status `ready`, performing any transition-time handling ARTIFACTS.md defines. Recommend `/mission-control:agentic-workflow sortie {NN}` to execute.

## Verb: List

Scan sorties at the location ARTIFACTS.md defines and report those not in a terminal state (`completed`, `aborted`). For each: number, title, status, age in days.

Flag sorties that have stalled: `planning` or `ready` for more than 30 days, and `landed` without a debrief. A landed sortie that is never debriefed loses its only retrospective — there is no mission debrief behind it to catch what it learned.

## Verb: Escalate

When a sortie turns out to be more than one flight's worth of work:

**If the sortie is `planning` or `ready`** (no code written):

1. Create the mission via `/mission-control:mission`, seeded with the charter — its outcome, why now, success criteria, and constraints become the mission's starting point, not a finished answer. The mission interview runs normally.
2. Once the mission is agreed, re-home the sortie as that mission's first flight, following ARTIFACTS.md for locations. Prefer moving over copy-and-delete, so file history survives. Replace the charter with the mission link and the criteria this flight contributes to.
3. Record the escalation in the flight log: which criterion failed and what was discovered.

**If the sortie is `in-flight` or later**: do not move it. Handle the change through `/mission-control:agentic-workflow`'s mid-execution scope rules — the flight lands with what it chartered, or is aborted — and plan the discovered work as a new sortie or mission that links back. Record the decision in the flight log.

The escalation gate is what keeps this path from becoming a bypass for mission planning. A sortie that quietly grows into a campaign has skipped every decision the mission gate exists to force.

## Integration Points

| Context | Behavior |
|---------|----------|
| **Execution** (`/mission-control:agentic-workflow sortie {NN}`) | Runs as any flight. There is no mission artifact to check off at landing. |
| **Debrief** (`/mission-control:flight-debrief sortie {NN}`) | The sortie's only debrief. Also assesses the charter's success criteria and whether a sortie was the right vehicle — work a mission debrief would otherwise do. |
| **Squawks** | A squawk that fails its gate only because it adds behavior, touches an interface, or needs one design call escalates to a sortie. |
| **Routine maintenance** | Recommended after several completed sorties with no mission in between, so a project running only sorties still gets inspected. |
| **Service reports** | A sortie counts as its own mission when a sweep measures a trend's span. |

## Guidelines

### The Charter Is Short

The charter is a few lines. If it needs stakeholders, a context essay, or more than four success criteria, the qualification gate is telling you it is a mission.

### One Sortie, One Outcome

Resist bundling. Two unrelated small features are two sorties. The sortie is the record, and a merged record cannot be individually escalated, aborted, or debriefed.

### Not a Shortcut Around Review

A sortie skips mission ceremony, not flight rigor. The Architect design review, the independent code review, and the debrief all happen. That rigor is what lets a sortie touch surfaces a squawk may not.

## Output

- **Plan**: the sortie artifact and its flight log, persisted per ARTIFACTS.md; report the sortie number, the charter, the leg breakdown, and the execution command
- **List**: sorties grouped by status, plus any stall flags
- **Escalate**: the criterion that failed, what was discovered, and the mission or follow-up it now belongs to
