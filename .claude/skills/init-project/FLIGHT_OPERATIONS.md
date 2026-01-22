# Flight Operations Quick Reference

> For full methodology docs, see [mission-control](https://github.com/flight-control/mission-control)

## Hierarchy

- **Missions** — Outcome-driven goals (days to weeks)
- **Flights** — Technical milestones with pre/post checklists (hours to days)
- **Legs** — Atomic implementation tasks with explicit acceptance criteria

## Implementation Workflow

1. Read the relevant mission, flight, and leg documentation
2. Read the flight-log.md for context from prior legs
3. Review the leg for accuracy and completeness — verify against the flight, mission, prior legs, project documentation, and existing code; update the leg if corrections or additions are needed before proceeding
4. Implement the leg requirements
5. Run code review before marking any leg complete
6. Address all Critical and Major issues from review
7. Re-review until no Critical/Major issues remain
8. Update documentation as needed:
   - Update internal code documentation
   - Update leg acceptance criteria if scope changed
   - Update flight plan acceptance criteria if requirements evolved
   - Update mission documentation if outcomes shifted
9. Update flight-log.md with:
   - Leg Progress entry (status, verification, review results)
   - Session Notes with implementation details
10. Mark leg complete and check off in the flight document

## Code Review Gate

```
Implement → Review → Fix Issues → Re-review → Complete
```

| Severity | Action |
|----------|--------|
| Critical | Must fix, no exceptions |
| Major | Must fix before marking complete |
| Minor | Present to user for decision |
| Suggestions | Present to user for decision |

## Flight Plan Structure

A flight plan (flight.md) contains:

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
2. **Prefer new legs over modifications** — If scope changes significantly, consider creating new legs; document any modifications or aborted legs in the flight log
3. **Binary acceptance criteria** — Met or not met, no judgment calls
4. **Log everything** — Decisions, deviations, anomalies go in the flight log
