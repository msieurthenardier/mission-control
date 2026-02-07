# Agent Prompt Templates

Reference prompts for the three-agent workflow. Mission Control (the `/agentic-workflow` skill) uses these when spawning Developer and Reviewer agents via the Task tool.

Substitute `{project-slug}`, `{flight-number}`, `{leg-number}`, and `{reviewer-issues}` before use.

---

## Developer: Implement

```
role: developer
phase: leg-implementation
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: implement

Read leg artifact. Implement to acceptance criteria. Update flight log with outcomes.
Propagate changes to artifacts (flight, mission, leg), CLAUDE.md, README, and other
project documentation as needed. Do NOT commit yet — signal [HANDOFF:review-needed]
when implementation is complete.
```

## Reviewer: Review

```
role: reviewer
phase: leg-review
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: review

Review all changes since the last commit. Evaluate against:
1. Leg acceptance criteria — are all criteria met?
2. Code quality — style, clarity, maintainability
3. Correctness — edge cases, error handling, security
4. Tests — coverage, meaningful assertions, no regressions
5. Artifacts — flight log updated, leg status correct

Signal [HANDOFF:confirmed] if all changes are satisfactory.
If issues found, list them with severity (blocking/non-blocking) and specific
file:line references.
```

## Developer: Fix Review Issues

```
role: developer
phase: leg-implementation
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: fix-review-issues

Address the following review feedback:
{reviewer-issues}

Fix all blocking issues. Non-blocking issues: fix if straightforward, otherwise
note as accepted. Signal [HANDOFF:review-needed] when fixes are complete.
```

## Developer: Commit

```
role: developer
phase: leg-implementation
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: commit

Review has passed. Commit all changes with appropriate message. Update leg status
to completed. Signal [COMPLETE:leg].
```
