# Agentic Workflow

Instructions for LLM orchestrators executing the Flight Control methodology with Claude Code.

## Prerequisites

Before starting any mission:

1. **Initialize target project**: Run `/init-project` in mission-control context targeting the project
2. **Register in projects.md**: Ensure target project is listed with path, remote, description
3. **Sync methodology**: Re-run `/init-project` if mission-control has been updated (syncs FLIGHT_OPERATIONS.md)

The orchestrator cannot proceed without `.flight-ops/ARTIFACTS.md` in the target project.

## Architecture

Two Claude Code instances, one orchestrator:

```
Orchestrator (you)
├── Mission Control instance (runs in mission-control/)
│   Role: Project management
│   Context lifespan: Entire flight
│
└── Project instance (runs in target project/)
    Role: Implementor/crew
    Context lifespan: One leg + next leg review, then clear
```

Artifacts are the shared state. Never pass files as context. Each Claude instance reads artifacts directly from its filesystem via the conventions in `.flight-ops/ARTIFACTS.md`.

## Invocation

```
exec pty:true workdir:/path/to/dir background:true command:"claude 'prompt' --dangerously-skip-permissions"
```

- **pty:true** — Required. Claude Code is interactive.
- **background:true** — For tasks longer than a few seconds.
- **--dangerously-skip-permissions** — Prevents approval prompts from blocking.

Poll and interact:
```
process action:poll sessionId:XXX    # check if running
process action:log sessionId:XXX     # read output
process action:submit sessionId:XXX data:"response"  # provide input
```

## Handoff Signals

Claude instances emit these markers. Monitor output for them.

| Signal | Meaning |
|--------|---------|
| `[HANDOFF:review-needed]` | Ready for other instance to review artifacts |
| `[HANDOFF:confirmed]` | Validation passed, proceed to next phase |
| `[BLOCKED:reason]` | Cannot proceed, needs resolution |
| `[COMPLETE:leg]` | Leg finished |
| `[COMPLETE:flight]` | Flight landed |
| `[COMPLETE:mission]` | Mission completed |

## Git Workflow

| Scope | Action |
|-------|--------|
| Flight start | Create branch: `flight/{number}-{slug}` |
| First leg | Open draft PR |
| Leg complete | Commit with leg reference |
| Flight landed | PR ready for review |

Commit message format:
```
leg/{number}: {description}

Flight: {flight-number}
Mission: {mission-number}
```

## Decision Autonomy

When Claude presents options with a recommendation:
- **Take the recommendation** if it fulfills the flight and mission objectives
- **Escalate to human** if you want to take a non-recommended path

Use the "discuss this" interaction with Claude when evaluating decisions. Pause workflow and wait for human response when escalating.

## Error Handling

| Situation | Action |
|-----------|--------|
| Claude error mid-leg | Attempt resume with context of what failed |
| Validation loops > 3 times | Escalate to human |
| Leg marked blocked | Escalate to human with blocker details |
| Off the rails | Roll back to last leg start commit |
| Severely off the rails | Roll back further, escalate to human |

## Workflow Phases

### Phase 1: Mission Planning

**Human-driven.** The orchestrator facilitates but the human defines outcomes.

**MC prompt:**
```
role: mission-control
phase: mission-planning
project: {project-slug}
action: create-mission

Research the project codebase. Interview the HUMAN for outcomes, success criteria, and constraints. Create mission artifact. Signal [HANDOFF:review-needed] when draft complete.
```

**Human review required.** Present the mission to the human for approval. Loop with human feedback until approved.

**Project prompt (review):**
```
role: crew
phase: mission-planning
project: {project-slug}
action: review-mission

Read the mission artifact. Validate alignment with project goals. Make changes if needed. Signal [HANDOFF:confirmed] if no changes, or describe changes made for MC validation.
```

**Loop** MC ↔ Project until both signal `[HANDOFF:confirmed]`, then **human approves final mission**.

---

### Phase 2: Flight Planning

**MC prompt:**
```
role: mission-control
phase: flight-planning
project: {project-slug}
mission: {mission-number}
action: create-flight

Read mission, design flight spec with legs. Signal [HANDOFF:review-needed] when complete.
```

**Project prompt (review):**
```
role: crew
phase: flight-planning
project: {project-slug}
flight: {flight-number}
action: review-flight

Read flight spec. Validate technical approach and leg breakdown. Make changes if needed. Signal [HANDOFF:confirmed] or describe changes.
```

**Loop** MC ↔ Project until both signal `[HANDOFF:confirmed]`.

**Human review required before first leg.** Present the flight spec to the human for approval before proceeding to leg execution.

**Git:** Create branch `flight/{number}-{slug}`.

---

### Phase 3: Leg Cycle

**Orchestrator-managed.** No human review required for individual legs. The orchestrator handles validation loops between MC and Project instances.

Repeat for each leg in the flight.

#### 3a: Leg Design

**MC prompt:**
```
role: mission-control
phase: leg-design
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: design-leg

Read flight spec and flight log. Design leg {leg-number} with acceptance criteria. Signal [HANDOFF:review-needed] when complete.
```

**Project prompt (review):**
```
role: crew
phase: leg-design
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: review-leg

Read leg artifact. Validate implementation guidance is complete and unambiguous. Make changes if needed. Signal [HANDOFF:confirmed] or describe changes.
```

**Loop** until both signal `[HANDOFF:confirmed]`.

**Git (first leg only):** Open draft PR.

#### 3b: Leg Implementation

**Clear Project context before this phase.**

**Project prompt:**
```
role: crew
phase: leg-implementation
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: implement

Read leg artifact. Implement to acceptance criteria. Update flight log with outcomes. Propagate changes to artifacts (flight, mission, leg), CLAUDE.md, README, and other project documentation as needed. Commit. Signal [COMPLETE:leg] when done.
```

**MC prompt (review):**
```
role: mission-control
phase: leg-review
project: {project-slug}
flight: {flight-number}
leg: {leg-number}
action: review-implementation

Review all changes from leg implementation. Validate acceptance criteria met. Signal [HANDOFF:confirmed] if satisfactory, or list items needing attention.
```

**Loop** if changes needed, then return to **3a** for next leg.

---

### Phase 4: Flight Completion

When all legs complete:

**MC prompt:**
```
role: mission-control
phase: flight-debrief
project: {project-slug}
flight: {flight-number}
action: debrief

Run /flight-debrief. Capture learnings. Update mission progress. Signal [COMPLETE:flight].
```

**Git:** PR ready for human review.

---

### Phase 5: Mission Completion

When all flights land:

**MC prompt:**
```
role: mission-control
phase: mission-debrief
project: {project-slug}
mission: {mission-number}
action: debrief

Run /mission-debrief. Capture outcomes assessment. Signal [COMPLETE:mission].
```

## Context Management

| Instance | When to clear |
|----------|---------------|
| Mission Control | After flight completes |
| Project | After leg implementation + next leg review |

Project reviews the next leg design *before* clearing, while implementation knowledge is fresh.

## Validation Protocol

A validation loop:

1. Producer signals `[HANDOFF:review-needed]`
2. Reviewer reads artifacts, evaluates
3. If changes needed: Reviewer makes changes, describes them
4. Producer validates changes
5. Repeat until both signal `[HANDOFF:confirmed]`

Exit condition: Both instances agree no further changes required.
