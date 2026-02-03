# Agentic Workflow

Instructions for LLM orchestrators executing the Flight Control methodology with Claude Code.

## Prerequisites

Before starting any mission:

1. **Initialize target project**: Run `/init-project` in mission-control context targeting the project
2. **Register in projects.md**: Ensure target project is listed with path, remote, description
3. **Sync methodology**: Re-run `/init-project` if mission-control has been updated (syncs FLIGHT_OPERATIONS.md)

The orchestrator cannot proceed without `.flight-ops/ARTIFACTS.md` in the target project.

## State Verification

Before starting or resuming any flight work, verify the current state:

1. **Read the flight log first** — This is the authoritative record of execution
2. **Cross-reference leg statuses** — Each leg's `**Status**:` field must match flight log entries
3. **Verify against codebase** — If discrepancies found, check actual files and git history
4. **Remediate discrepancies immediately** — They compound over time; fix before proceeding

If the flight log says "not started" but leg files show completion, or vice versa, treat this as a blocking issue requiring remediation before any new work.

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

### Signal Format

**Placement:** Signals must appear on their own line at the end of a Claude response. Never mid-paragraph.

**Detection regex:**
```
^\[(HANDOFF|BLOCKED|COMPLETE):[^\]]+\]$
```

**No-signal fallback:** If Claude completes a response without emitting an expected signal, treat as implicit `[BLOCKED:no-signal]`. Prompt with:
```
action:submit data:"Expected signal not received. What is the current status? Emit appropriate signal."
```

## Git Workflow

| Scope | Action |
|-------|--------|
| Flight start | Create branch: `flight/{number}-{slug}` |
| First leg | Open draft PR |
| Leg complete | Commit code + artifacts with leg reference |
| Flight landed | PR ready for review |

**Each leg commit must include:**
- Code changes
- Updated flight log
- Updated leg status
- Any mission/flight artifact changes

**Artifact consistency rule:** The flight log is the authoritative record. After each leg:
- Flight log must have an entry for the completed leg
- Leg file must have `**Status**: completed` in its header
- These must match — if they don't, remediation is required before proceeding

This ensures `git reset --hard` restores both code and artifacts atomically.

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

Pause workflow and wait for human response when escalating.

### Interactive Discussion

Use discussion mode to ask clarifying questions without restarting an instance.

**Enter discussion:**
```
action:submit data:"[DISCUSS] How does this approach handle concurrent requests?"
```

Claude responds conversationally without emitting signals. Ask follow-up questions as needed.

**Exit discussion:**
```
action:submit data:"[/DISCUSS] Proceed with the recommendation."
```

Claude resumes normal operation and emits appropriate signal.

**Rules:**
- Discussion does not count toward liveness timeouts
- Claude should not emit handoff signals during discussion
- Keep discussions focused; open-ended exploration should escalate to human

## Error Handling

| Situation | Action |
|-----------|--------|
| Claude error mid-leg | Attempt resume with context of what failed |
| Validation loops > 3 times | Escalate to human |
| Leg marked blocked | Escalate to human with blocker details |
| Off the rails | Roll back to last leg start commit |
| Severely off the rails | Roll back further, escalate to human |
| Artifact discrepancy found | Remediate before proceeding; do not continue with inconsistent state |

### Rollback Recovery

Each leg commit includes all artifact changes (flight log, mission status, leg status). Rolling back a commit restores both code and artifacts to a consistent state.

When rolling back:
1. `git reset --hard {commit}` restores code + artifacts atomically
2. Re-read restored artifacts to understand state
3. Resume from that leg, or escalate if unclear

## Liveness

Monitor for hung or stalled instances.

| Timeout | Trigger | Action |
|---------|---------|--------|
| Progress | No new output for 5 min | Send ping: `action:submit data:"Status?"` |
| Response | No signal within 10 min of ping | Escalate to human |
| Hard | 30 min total for any phase | Force terminate, escalate to human |

Timeouts reset when Claude produces meaningful output (not just acknowledgments).

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

**Skill shortcut:** Mission Control has built-in skills for common operations. Instead of crafting full prompts, you can use natural commands like:
- `design leg 04 for {project} mission {number} flight {number}`
- The skill handles reading artifacts and creating properly formatted leg files.

**Expected runtime:** Leg design via skills typically takes 1-3 minutes. MC gathers extensive context before generating — reading the flight spec, mission doc, design docs, mockups, and existing code. This thorough context gathering produces better leg specs. Do not interrupt prematurely.

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

### Multi-Flight Continuity

Mission Control clears between flights to manage context size. Continuity is maintained through artifacts:

**Before starting each flight, MC must read:**
1. Mission artifact (outcomes, success criteria, constraints)
2. All completed flight debriefs (learnings, what changed)
3. Current mission status/progress

This ensures strategic context persists across a multi-flight mission without requiring unbounded context retention.

## Validation Protocol

A validation loop:

1. Producer signals `[HANDOFF:review-needed]`
2. Reviewer reads artifacts, evaluates
3. If changes needed: Reviewer makes changes, describes them
4. Producer validates changes
5. Repeat until both signal `[HANDOFF:confirmed]`

Exit condition: Both instances agree no further changes required.
