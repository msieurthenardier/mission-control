# Flight Operations Quick Reference

> For full methodology docs, see [mission-control](https://github.com/flight-control/mission-control)

## Hierarchy

- **Missions** — Outcome-driven goals (days to weeks)
- **Flights** — Technical milestones with pre/post checklists (hours to days)
- **Legs** — Atomic implementation tasks with explicit acceptance criteria

## Implementation Workflow

1. Read the relevant mission, flight, and leg documentation
2. Read the flight-log.md for context from prior legs
3. Implement the leg requirements
4. Run code review before marking any leg complete
5. Address all Critical and Major issues from review
6. Re-review until no Critical/Major issues remain
7. Update flight-log.md with:
   - Leg Progress entry (status, verification, review results)
   - Session Notes with implementation details
8. Check off completed legs in the flight document

## Code Review Gate

```
Implement → Review → Fix Issues → Re-review → Complete
```

| Severity | Action |
|----------|--------|
| Critical | Must fix, no exceptions |
| Major | Must fix before marking complete |
| Minor | Fix if straightforward, otherwise note in flight-log |
| Suggestions | Document for future consideration |

## Key Principles

1. **Read the flight log first** — It's ground truth for what actually happened
2. **Immutability** — Never modify legs once in-progress; create new ones
3. **Binary acceptance criteria** — Met or not met, no judgment calls
4. **Log everything** — Decisions, deviations, anomalies go in the flight log
