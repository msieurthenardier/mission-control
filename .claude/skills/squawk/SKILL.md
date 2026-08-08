---
name: squawk
description: Log and complete squawks — small, standalone defects and routine servicing updates that don't warrant a mission. Use for bug fixes, dependency bumps, config corrections, and doc fixes. Also the holding pen for out-of-scope defects found mid-flight.
---

# Squawk

In aviation, a **squawk** is a discrepancy logged in the aircraft's logbook. A mechanic clears it with a recorded corrective action, signed off by someone other than the person who reported it. Small squawks are handled on the turnaround; anything bigger sends the aircraft to the hangar.

A squawk is Flight Control's unit for work too small to be a mission. It is **not** part of the mission → flight → leg hierarchy — it stands beside it, with no parent and no debrief.

## When to Use

**Log a squawk** when work meets **all four** of these:

1. **One coherent item** — a single defect or a single routine update
2. **No design decisions** — the fix approach is obvious, or discoverable in one read pass
3. **Bounded blast radius** — no shared-interface changes, no schema/migration changes, no lifecycle or state-machine changes, no security-sensitive surface
4. **Verifiable** — an existing test covers it, or one new test does

If any one of these fails, it is not a squawk. Recommend `/mission` (new outcome) or `/flight` (new work under an active mission) instead, and say which criterion it failed.

**Types:**

| Type | Meaning | Examples |
|------|---------|----------|
| `defect` | Something is broken | Null check, off-by-one, wrong error message, broken link, failing edge case |
| `servicing` | Routine upkeep, nothing broken | Dependency bump, lint rule, config correction, doc fix, log-level change |

**Severity:**

| Severity | Meaning |
|----------|---------|
| `grounding` | Must be completed before further work in the affected area |
| `routine` | Can be carried; picked up at the next convenient turnaround |

**Status**: `open` → `in-progress` → `completed`, or `deferred` / `escalated`.

## Prerequisites

- Project must be initialized with `/init-project` (`.flightops/ARTIFACTS.md` must exist with a Squawk section — run `/init-project` to apply migration 006 if missing)

## Invocation

```
/squawk {description}                      Log a new squawk
/squawk list                               List open, in-progress, and deferred squawks
/squawk complete {id} [{id} ...]         Complete one squawk or a batch
/squawk defer {id}                        Carry a squawk forward with a reason
/squawk escalate {id}                     Promote to a flight or mission
```

Add `for {project-slug}` to any form to target a specific project. If omitted and the project is ambiguous, ask.

## Context Loading (all verbs)

1. **Read `projects.md`** to find the target project's path
2. **Read `{target-project}/.flightops/ARTIFACTS.md`** for how this project handles the squawk artifact — its storage location, format, naming/sequence conventions, Git Conventions, and any actions the project defines at create and transition time (e.g. opening a ticket, posting a notification). Honor these whenever you or a spawned agent creates a squawk or moves one through its lifecycle.
   - **If ARTIFACTS.md has no squawk conventions**: STOP and tell the user to run `/init-project` to apply migration 006.
3. **Read `{target-project}/.flightops/agent-crews/leg-execution.md`** for crew definitions and prompts (fall back to defaults at `.claude/skills/init-project/defaults/agent-crews/leg-execution.md`). Squawks reuse the leg-execution crew — Developer and Reviewer — rather than defining their own.
   - **If the file exists but is malformed** (missing `## Crew`, `## Interaction Protocol`, or `## Prompts` with fenced code blocks): STOP and tell the user to fix it or re-run `/init-project`. Do not improvise missing prompts.

## Verb: Log

1. **Qualify it.** Check the four criteria above out loud. If it fails one, say which, recommend `/mission` or `/flight`, and stop — do not log a squawk as a workaround for scope.
2. **Interview briefly** — this is a lightweight artifact, so keep it to what's missing. At most:
   - For a `defect`: what was observed, where, and how to reproduce
   - For `servicing`: what needs updating and why now
   - Severity: `grounding` or `routine`
   Skip any question the user's description already answers.
3. **Gather evidence yourself** rather than asking for it. Read the relevant code, run the failing command, check the current dependency version. Cite durably — prefer `file:symbol` or `file:line — "snippet"` over bare line numbers. Keep it to a few lines; a squawk is not an investigation report.
4. **Assign the next sequence number** by scanning existing squawks at the location ARTIFACTS.md defines, following the project's naming conventions.
5. **Write the artifact** with status `open`, persisted per ARTIFACTS.md, then perform any create-time handling the project defines for it.
6. **Offer to complete it now** if severity is `grounding`, or if the user is not mid-flight. Otherwise leave it open.

## Verb: List

Scan squawks at the location ARTIFACTS.md defines and report those not in a terminal state (`completed`, `escalated`), grouped by severity with `grounding` first. For each: id, title, type, status, age in days.

Flag squawks that have gone stale: `grounding` open more than 7 days, `routine` open more than 30 days. A squawk log that rots is worse than no log — call it out.

## Verb: Complete

Completion is where the Developer/Reviewer separation applies. **Never implement directly** — spawn agents.

Multiple squawks may be completed in one pass. That batching is the point: one branch, one review, one commit for several small items, the way a mechanic clears several open logbook items on a single visit.

### 1. Confirm the batch

Read each named squawk. Reject any already `completed` or `escalated`. Present the batch and confirm before starting.

### 2. Create the branch

Per the project's Git Conventions in ARTIFACTS.md, using the squawk branch scheme (single vs. batch).

### 3. Spawn a Developer per squawk — sequentially

Sequential, not parallel: the agents share one working tree, and concurrent edits collide.

For each squawk, spawn a Developer (Task tool, `subagent_type: "general-purpose"`, working directory `{target-project}`) with the "Implement" prompt from the leg-execution crew file, adapted to the squawk. In your spawn prompt, state directly — do not assume the crew file carries it:

- The squawk's report, evidence, and severity
- That it must update the squawk's status to `in-progress`, and perform any transition-time handling the project's ARTIFACTS.md defines for that transition (default: none)
- That it must record the **corrective action** and **verification** in the squawk artifact
- That it must **NOT commit** — the Flight Director commits after review
- **The scope gate**: if the fix turns out to require design decisions, touch shared interfaces or schemas, or spread beyond the reported surface, it must stop, revert its changes, and emit `[BLOCKED:exceeds-squawk-scope]` with an explanation — rather than growing the fix

Then update the squawk's status to `in-progress`.

### 4. Handle scope breaches

On `[BLOCKED:exceeds-squawk-scope]`: verify the working tree is clean of that squawk's changes, mark it `escalated` (see the Escalate verb), drop it from the batch, and continue with the rest. Report it to the user at the end — do not silently expand a squawk into real work.

### 5. Spawn one Reviewer for the whole batch

Spawn a Reviewer (Task tool, `subagent_type: "general-purpose"`, working directory `{target-project}`) with the "Review" prompt from the leg-execution crew file. In your spawn prompt, state directly:

- Each squawk's report and its recorded corrective action
- That the review is **scoped to the diff** — verify each squawk's corrective action is correct, complete, tested, and confined to the reported surface. Do not open adjacent quality questions; anything worth fixing beyond the diff gets logged as a new squawk, not folded into this one.
- That it signals `[HANDOFF:confirmed]`, or lists issues with severity and `file:line` references

The Reviewer has no knowledge of any Developer's reasoning — only the resulting changes. That separation is the sign-off, and it is not optional, however small the fix.

### 6. Fix loop

On issues, spawn a Developer with the "Fix Review Issues" prompt and the Reviewer's feedback. Re-review. **Max 3 cycles** — escalate to the human if issues persist.

### 7. Commit and close out

After the Reviewer confirms:

1. Update each squawk artifact: status `completed`, completion date, sign-off (reviewer verdict), and the commit reference — performing any transition-time handling ARTIFACTS.md defines
2. Commit code and squawk artifacts together, per the project's Git Conventions squawk commit scheme
3. Open a PR, ready for review — not draft. A squawk has no multi-leg progression to track.
4. Signal `[COMPLETE:squawk]`

## Verb: Defer

Set status `deferred` and record the reason and a revisit trigger ("next time this module is touched", "after flight 04 lands", "when the upstream fix ships"). A deferral without a trigger is just an open squawk with extra steps — insist on one.

Deferred squawks are carried, not forgotten: they surface in `/squawk list`, in `/daily-briefing`, and as input to `/routine-maintenance`.

## Verb: Escalate

When a squawk turns out to exceed its scope:

1. Set status `escalated` and record which of the four criteria it failed and what was discovered
2. Confirm no partial changes remain in the working tree
3. Recommend the right vehicle — `/flight` if an active mission covers it, `/mission` if not
4. Once the flight or mission exists, link it from the squawk

The escalation gate is what keeps this path from becoming a bypass for real work. Aviation has the same rule: open the panel, find something bigger, and the aircraft goes to the hangar.

## Integration Points

| Context | Behavior |
|---------|----------|
| **Mid-flight** (`/agentic-workflow`) | A defect found outside the current flight's scope gets logged as a `routine` squawk and deferred. The flight keeps flying. A `grounding` squawk in the flight's own path is completed before the flight continues. |
| **Flight debrief** | Action items that are small and concrete become squawks with ids, rather than bullets that die in the debrief. |
| **Routine maintenance** | Open and deferred squawks are prior context for the inspection. Advisory one-liners are logged as squawks instead of scaffolding a mission. |
| **Daily briefing** | Open squawk counts and stale-squawk alerts per project. |

## Guidelines

### Keep It Small

A squawk artifact that takes longer to write than the fix takes to make is a failed squawk. The report and evidence together should be a handful of lines. If the item genuinely needs more, that is the qualification gate telling you it is a flight.

### One Squawk, One Item

Resist bundling. Two unrelated defects are two squawks, even if you complete them in the same batch. The batch is an execution convenience; the artifact is the record, and a merged record can't be individually deferred, escalated, or reverted.

### The Sign-Off Is Non-Negotiable

Every completed squawk gets an independent Reviewer, however trivial the change. The review is scoped tightly and batched so it stays cheap — but it happens. Aviation signs off the bulb swap too.

### Squawks Are Not a Backlog

This is a defect log, not a feature tracker. Anything that adds behavior a user would notice as new is a mission or a flight, no matter how small it looks. If the answer to "is this broken?" is no and the answer to "is this upkeep?" is also no, it does not belong here.

## Output

Deliverable: the squawk artifact(s), persisted per the conventions ARTIFACTS.md defines.

- **Log**: report the squawk id, type, severity, and whether it was left open or completed immediately
- **Complete**: report which squawks were completed, which escalated, the review outcome, and the commit/PR
- **List**: the grouped list plus any staleness flags
