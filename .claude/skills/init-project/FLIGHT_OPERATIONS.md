# Flight Operations Quick Reference

> For full methodology docs, see [mission-control](https://github.com/flight-control/mission-control)

## Hierarchy

- **Missions** — Outcome-driven goals (days to weeks)
- **Flights** — Technical milestones with pre/post checklists (hours to days)
- **Legs** — Atomic implementation tasks with explicit acceptance criteria

## Implementation Workflow

Follow this workflow when implementing a leg:

1. Read the relevant mission, flight, and leg documentation
2. Read the flight log for context from prior legs
3. Review the leg for accuracy and completeness — verify against the flight, mission, prior legs, project documentation, and existing code
4. Present a summary to the user before implementation:
   - Overview of what the leg requires
   - Any questions or ambiguities identified
   - Recommended changes to the leg documentation (if any)
   - Wait for user approval before proceeding
5. Implement the leg requirements
6. Run appropriate tests for the changes
7. Run code review before marking any leg complete
8. Address all Critical and Major issues from review
9. Re-review until no Critical/Major issues remain
10. Update documentation as needed:
    - Update internal code documentation
    - Update leg acceptance criteria if scope changed
    - Update flight plan acceptance criteria if requirements evolved
    - Update mission documentation if outcomes shifted
11. Update the flight log with:
    - Leg Progress entry (status, verification, review results)
    - Session Notes with implementation details
    - Any deferred issues (test failures, minor code issues not addressed)
12. Mark leg complete and check off in the flight document

## Code Review Gate

```
Implement → Test → Review → Fix Issues → Re-review → Complete
```

| Severity | Action |
|----------|--------|
| Critical | Must fix, no exceptions |
| Major | Must fix before marking complete |
| Minor | Fix if simple and safe; otherwise present to user |
| Suggestions | Fix if simple and safe; otherwise present to user |

**Existing Issues:** Pre-existing code issues discovered during review should be presented to the user to determine whether to address them now or defer. If deferred, note them in the flight log.

## Test Verification

Run tests appropriate to the changes made. Handle failures as follows:

| Type | Action |
|------|--------|
| Related failures | Must fix before marking complete |
| Unrelated failures | Present to user for decision |

**Deferred test failures:** If the user decides not to address unrelated test failures, document them in the flight log with context for future resolution.

## Flight Plan Structure

A flight plan contains:

- **Overview** — Purpose, scope, and relationship to mission
- **Pre-flight Checklist** — Prerequisites that must be verified before starting
- **Acceptance Criteria** — Binary conditions that define flight success
- **Legs** — Ordered list of implementation tasks with status checkboxes
- **In-flight Checklist** — Ongoing verification during implementation
- **Post-flight Checklist** — Final verification before marking complete
- **Risk Assessment** — Known risks and mitigation strategies

Update acceptance criteria during implementation if requirements evolve, but document changes in the flight log.

## Key Principles

1. **Read the flight log first** — It's ground truth for what actually happened
2. **Never modify legs once `in-progress`** — Create new legs instead; modifications are only allowed while `queued`
3. **Binary acceptance criteria** — Met or not met, no judgment calls
4. **Log everything** — Decisions, deviations, anomalies go in the flight log
