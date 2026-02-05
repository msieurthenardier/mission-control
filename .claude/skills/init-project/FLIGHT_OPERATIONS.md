# Flight Operations Quick Reference

> For full methodology docs, see [mission-control](https://github.com/flight-control/mission-control)

## Before You Start

**Read these files in order:**
1. `.flight-ops/ARTIFACTS.md` — Where and how artifacts are stored (project-specific)
2. The **flight log** for your active flight — Ground truth for what happened
3. The **leg artifact** you're implementing — Your acceptance criteria

---

## ⚠️ Leg Completion Checklist (MANDATORY)

**You MUST complete ALL of these before emitting `[COMPLETE:leg]`:**

| Step | Action |
|------|--------|
| 1 | All acceptance criteria verified |
| 2 | Tests passing |
| 3 | **Update flight log** — Add leg progress entry (see below) |
| 4 | **Mark leg complete** — Update leg status |
| 5 | **Update flight** — Check off the leg in flight artifact |
| 6 | **Commit/save with all artifact updates** |

**Flight log entry MUST include:**
- Leg status, started date, completed date
- Changes Made (what was implemented)
- Verification (how acceptance criteria were confirmed)
- Any decisions, deviations, or anomalies

Refer to `.flight-ops/ARTIFACTS.md` for exact locations and formats.

---

## Workflow Signals

Emit at the end of your response, on its own line:

| Signal | When |
|--------|------|
| `[HANDOFF:review-needed]` | Artifact changes ready for validation |
| `[HANDOFF:confirmed]` | Review complete, no issues |
| `[BLOCKED:reason]` | Cannot proceed |
| `[COMPLETE:leg]` | Leg done AND checklist complete |

---

## Implementing a Leg

### Pre-Implementation
1. Read mission, flight, and leg artifacts
2. Read flight log for context from prior legs
3. Verify leg accuracy against existing code
4. Present summary and get approval before proceeding

### Implementation
5. Implement to acceptance criteria
6. Run tests
7. Run code review, fix Critical/Major issues
8. Re-review until clean

### Post-Implementation
9. Propagate changes (project docs, flight artifacts if scope changed)
10. **Complete the Leg Completion Checklist above**
11. Signal `[COMPLETE:leg]`

---

## Just-in-Time Planning

Flights and legs are created one at a time, not upfront.

| Reviewing... | Should exist | Should NOT exist yet |
|--------------|--------------|----------------------|
| Mission | Mission artifact | Flight artifacts (only listed) |
| Flight | Flight artifact | Leg artifacts (only listed) |
| Leg | Leg artifact | Ready to implement |

Listed flights/legs are **tentative suggestions** that evolve based on discoveries.

---

## Reviewing Artifacts

When reviewing a mission, flight, or leg:

1. Read the artifact thoroughly
2. Validate against project goals and existing code
3. Check for ambiguities or missing details
4. Make changes directly if needed
5. Describe any changes made
6. Signal `[HANDOFF:confirmed]` if no issues, or describe changes for validation

---

## Code Review Gate

```
Implement → Test → Review → Fix → Re-review → Complete
```

| Severity | Action |
|----------|--------|
| Critical | Must fix |
| Major | Must fix |
| Minor | Fix if safe, else defer |

Deferred issues go in the flight log.

---

## ⚠️ Flight Completion Checklist (MANDATORY)

**When you complete the FINAL leg of a flight, also complete these steps:**

| Step | Action |
|------|--------|
| 1 | Complete all items in the Leg Completion Checklist above |
| 2 | **Update flight log** — Add flight completion entry with summary |
| 3 | **Update flight status** — Set `**Status**: landed` in flight.md |
| 4 | **Update mission** — Check off this flight in mission.md |
| 5 | **Verify all legs** — Confirm all legs show `completed` status |
| 6 | Signal `[COMPLETE:leg]` (the orchestrator will trigger Phase 4) |

The orchestrator will then:
- Mark the PR ready for human review
- Invoke Mission Control for flight debrief

---

## Key Principles

1. **Flight log is ground truth** — Read it first, update it always
2. **Never modify in-progress legs** — Create new ones instead
3. **Binary acceptance criteria** — Met or not met
4. **Log everything** — Decisions, deviations, anomalies
5. **Signal clearly** — End of response, own line
