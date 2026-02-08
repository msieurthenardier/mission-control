# Agent Prompt Templates

Reference prompts for the three-agent workflow. Mission Control (the `/agentic-workflow` skill) uses these when spawning Developer and Reviewer agents via the Task tool.

Substitute `{project-slug}`, `{flight-number}`, `{leg-number}`, `{reviewer-issues}`, `{flight-artifact-path}`, and `{leg-artifact-path}` before use.

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

## Developer: Review Flight Design

```
role: developer
phase: flight-design-review
project: {project-slug}
flight: {flight-number}
action: review-flight-design

Read the flight artifact at {flight-artifact-path}. Cross-reference its design
decisions, prerequisites, technical approach, and leg breakdown against the actual
codebase state.

Evaluate:
1. Design decisions — are they sound given the real codebase?
2. Prerequisites — are they accurate? Is anything missing or already done?
3. Technical approach — is it feasible? Does it account for existing patterns?
4. Leg breakdown — are legs well-scoped, properly ordered, with correct dependencies?
5. Codebase state — does the spec account for current working tree, existing tooling,
   and conventions that might affect implementation?

Provide structured output:

**Overall assessment**: approve | approve with changes | needs rework

**Issues** (ranked by severity):
- [high/medium/low] Description — recommended fix

**Suggestions** (non-blocking improvements):
- Description

**Questions** (for the designer to clarify):
- Question
```

## Developer: Review Leg Design

```
role: developer
phase: leg-design-review
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: review-leg-design

Read the leg artifact at {leg-artifact-path}. Cross-reference its acceptance
criteria, implementation guidance, and file references against the actual codebase
state.

Evaluate:
1. Acceptance criteria — are they specific, verifiable, and complete?
2. Implementation guidance — is it complete and correctly ordered?
3. Edge cases — are there missing scenarios the guidance doesn't address?
4. Codebase state — does the leg account for current working tree state, existing
   tooling that might break, dirty files, or uncommitted changes?
5. File/line references — are they accurate against the current codebase?
6. Dependencies — are prerequisite legs actually completed? Are their outputs available?

Provide structured output:

**Overall assessment**: approve | approve with changes | needs rework

**Issues** (ranked by severity):
- [high/medium/low] Description — recommended fix

**Suggestions** (non-blocking improvements):
- Description

**Questions** (for the designer to clarify):
- Question
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
