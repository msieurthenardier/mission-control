# Flight Operations Quick Reference

> For full methodology docs, see [mission-control](https://github.com/flight-control/mission-control)

## Workflow Signals

Emit these signals at the end of your response when appropriate:

| Signal | When to emit |
|--------|--------------|
| `[HANDOFF:review-needed]` | Artifact changes complete, ready for validation |
| `[HANDOFF:confirmed]` | Review complete, no changes needed |
| `[BLOCKED:reason]` | Cannot proceed without resolution |
| `[COMPLETE:leg]` | Leg implementation finished and committed |

## Hierarchy

- **Missions** — Outcome-driven goals (days to weeks)
- **Flights** — Technical milestones with pre/post checklists (hours to days)
- **Legs** — Atomic implementation tasks with explicit acceptance criteria

Read `.flight-ops/ARTIFACTS.md` to find artifact locations.

## Just-in-Time Planning

**Flights and legs are created one at a time, not all upfront.** This is by design.

| When reviewing... | What should exist | What should NOT exist yet |
|-------------------|-------------------|---------------------------|
| A mission | The mission document | Flight documents (only listed in mission) |
| A flight | The flight document | Leg documents (only listed in flight) |
| A leg | The leg document | (ready to implement) |

**Why this matters:**
- Listed flights in a mission are **tentative suggestions** — they will change as work progresses
- Listed legs in a flight are **tentative suggestions** — they will change based on discoveries
- Creating artifacts just-in-time ensures they're based on **current reality**, not stale assumptions
- Feedback from completed work should inform the next flight/leg design

**This is not a problem.** If you're implementing a leg and only see one flight defined, that's correct. If you're reviewing a mission and see no flight documents created yet, that's correct. The planning happens incrementally as the work evolves.

## Reviewing Artifacts

When reviewing a mission, flight, or leg:

1. Read the artifact thoroughly
2. Validate against project goals and existing code
3. Check for ambiguities or missing details
4. Make changes directly to the artifact if needed
5. Describe any changes made
6. Signal `[HANDOFF:confirmed]` if no issues, or describe changes for validation

## Implementing a Leg

1. Read the mission, flight, and leg documentation
2. Read the flight log for context from prior legs
3. Review the leg for accuracy — verify against flight, mission, and existing code
4. Present a summary before implementation:
   - What the leg requires
   - Any questions or ambiguities
   - Recommended changes (if any)
   - Wait for approval before proceeding
5. Implement the leg requirements
6. Run appropriate tests
7. Run code review before marking complete
8. Address all Critical and Major issues
9. Re-review until no Critical/Major issues remain
10. Propagate changes as needed:
    - Update leg acceptance criteria if scope changed
    - Update flight plan if requirements evolved
    - Update mission documentation if outcomes shifted
    - Update CLAUDE.md with new patterns or conventions
    - Update README and other project documentation
11. Update the flight log with:
    - Leg progress entry (status, verification, review results)
    - Session notes with implementation details
    - Any deferred issues
12. Commit with message: `leg/{number}: {description}`
13. Mark leg complete in the flight document
14. Signal `[COMPLETE:leg]`

## Code Review Gate

```
Implement → Test → Review → Fix Issues → Re-review → Complete
```

| Severity | Action |
|----------|--------|
| Critical | Must fix, no exceptions |
| Major | Must fix before marking complete |
| Minor | Fix if simple and safe; otherwise present for decision |
| Suggestions | Fix if simple and safe; otherwise present for decision |

**Existing Issues:** Pre-existing issues discovered during review should be presented to determine whether to address now or defer. If deferred, note in flight log.

## Test Verification

| Type | Action |
|------|--------|
| Related failures | Must fix before marking complete |
| Unrelated failures | Present for decision |

**Deferred failures:** Document in flight log with context for future resolution.

## Key Principles

1. **Read the flight log first** — It's ground truth for what actually happened
2. **Never modify legs once `in-progress`** — Create new legs instead
3. **Binary acceptance criteria** — Met or not met, no judgment calls
4. **Log everything** — Decisions, deviations, anomalies go in the flight log
5. **Signal clearly** — Emit signals at the end of your response
