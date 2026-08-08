# Squawks

A **squawk** is Flight Control's unit for work too small to plan: one bug fix, or one routine servicing update. It stands beside the mission → flight → leg hierarchy rather than inside it — no parent, no legs, no debrief.

## Why Squawks Exist

Flight Control's smallest planning unit used to be a mission. A one-line null check therefore needed a mission, a flight, a leg, a branch, a review, and a debrief. In practice that meant small fixes went one of two ways: done off-methodology, invisible and untraceable, or inflated into a maintenance mission that cost more to plan than to do.

There was a second, quieter gap. A defect discovered mid-flight but outside that flight's charter had nowhere to live. It either got folded into the leg in hand — quietly deforming the flight — or was mentioned in a debrief bullet and forgotten. Squawks are the holding pen those findings never had.

## The Aviation Model

A squawk is a discrepancy a pilot writes into the aircraft's logbook: what was observed, and when. A mechanic later clears it by recording the corrective action taken, and a second person signs the clearance off. Small squawks are cleared on the turnaround between flights. When a mechanic opens a panel and finds something bigger than the logbook entry suggested, the aircraft goes to the hangar — the squawk does not quietly grow into an overhaul.

Every part of that maps: the report/clearance split, the independent sign-off, the batching on turnaround, and — most importantly — the escalation rule.

## Qualification

Something is a squawk only if **all four** hold:

1. **One coherent item** — a single defect or a single routine update
2. **No design decisions** — the approach is obvious, or discoverable in one read pass
3. **Bounded blast radius** — no shared-interface changes, no schema or migration changes, no lifecycle or state-machine changes, no security-sensitive surface
4. **Verifiable** — an existing test covers it, or one new test does

Fail any one and it is a flight or a mission, not a squawk.

**The gate matters more than the criteria.** A squawk that turns out to need design work is marked `escalated` and handed to `/flight` or `/mission`, with its partial changes reverted. It is never expanded in place. Without that rule the lightweight path becomes a bypass for real work, and the methodology's value — that consequential decisions get planned and reviewed — leaks away one "quick fix" at a time.

## Anatomy

| Field | Meaning |
|-------|---------|
| **Type** | `defect` (something is broken) or `servicing` (routine upkeep — dependency bump, lint rule, config, doc fix) |
| **Severity** | `grounding` (complete before further work in the affected area) or `routine` (carry to the next turnaround) |
| **Status** | `open` → `in-progress` → `completed`, or `deferred` / `escalated` |

Ids are monotonically increasing integers, zero-padded to a minimum of four digits and widening past that as needed. They are unbounded by design — a long-lived project will pass any fixed width — and never reused, so a completed or escalated squawk's id stays a stable reference forever.

The artifact has two halves. The **report** — observation, evidence, severity — is written when the squawk is logged. The **corrective action, verification, and sign-off** are written at completion. Evidence and corrective action are both short by design: a squawk that takes longer to document than to fix is a failed squawk.

Squawks deliberately do not use the unified `planning → ready → in-flight → landed → completed` lifecycle. A squawk has no planning phase, and forcing the symmetry would describe a stage that does not exist.

## Completing

Completion runs the same separation as a leg, at a smaller scale. A Developer agent implements the fix; an independent Reviewer, with no knowledge of the Developer's reasoning, signs off on the diff. That sign-off is not waived for trivial changes — aviation signs off the bulb swap too. What keeps it cheap is scope and batching: the review is confined to the diff, and several open squawks are completed in a single pass with one branch, one review, and one commit.

Batching is the efficiency win over treating each fix as a flight. It is also true to the model — a mechanic clears several open logbook items on one visit.

Anything the Reviewer notices beyond the diff becomes a new squawk. It does not get folded into the one in hand; that is the same failure mode the escalation gate exists to prevent, just arriving from the other direction.

## Where Squawks Come From

| Source | How |
|--------|-----|
| **Direct observation** | Someone notices something broken and logs it |
| **Mid-flight discovery** | `/agentic-workflow` logs out-of-scope defects and defers them, keeping the flight's shape intact |
| **Flight debrief** | Small concrete action items become squawks with ids instead of bullets that die in the debrief |
| **Routine maintenance** | Squawk-sized findings are logged rather than scaffolded into a mission; open squawks feed back in as known debt |

`/daily-briefing` reports open counts and flags stale squawks — `grounding` open past 7 days, `routine` past 30, or anything stuck `in-progress`. A log that only grows means small fixes are being captured but never completed, which is a finding in itself.

## What Squawks Are Not

**Not a backlog.** This is a defect log, not a feature tracker. Anything that adds behavior a user would notice as new is a mission or a flight, however small it looks. If "is this broken?" is no and "is this upkeep?" is also no, it does not belong here.

**Not a bundle.** Two unrelated defects are two squawks, even when completed in the same batch. The batch is an execution convenience; the artifact is the record, and a merged record cannot be individually deferred, escalated, or reverted.

**Not a shortcut.** The qualification gate is the price of the lightweight path. Work that fails it is not a squawk that happens to be large — it is a flight that has not been planned yet.

## See Also

- [Missions](missions.md) — outcome-driven planning for work that does need a mission
- [Flights](flights.md) — technical specifications
- [Workflow](workflow.md) — end-to-end flow from mission to completion
