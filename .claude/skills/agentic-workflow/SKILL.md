---
name: agentic-workflow
description: Active orchestrator for multi-agent flight execution. Drives the full leg cycle (design, implement, review, commit) using three separate Claude instances.
---

# Agentic Workflow

Orchestrate multi-agent flight execution. You drive the full leg cycle — designing legs, spawning Developer and Reviewer agents, and managing git workflow — for a target project's flight.

## Prerequisites

- Project must be initialized with `/init-project` (`.flight-ops/ARTIFACTS.md` must exist)
- A mission must exist and be `active`
- A flight must exist and be `ready` or `in-flight`

## Invocation

```
/agentic-workflow flight {number} for {project-slug} mission {number}
```

Example: `/agentic-workflow flight 03 for epipen mission 04`

## Phase 1: Context Loading

1. **Read `projects.md`** to find the target project's path
2. **Read `{target-project}/.flight-ops/ARTIFACTS.md`** for artifact locations
3. **Read the mission artifact** — outcomes, success criteria, constraints
4. **Read the flight artifact** — objective, design decisions, leg list
5. **Read the flight log** — ground truth from prior execution
6. **Count total legs** from the flight spec — track progress throughout
7. **Determine starting point** — which leg is next based on flight log and leg statuses

If resuming a flight already in progress, verify state consistency:
- Flight log entries must match leg statuses
- If discrepancies exist, remediate before proceeding

## Phase 2: Leg Cycle

Repeat for each leg in the flight.

### 2a: Leg Design

1. **Design the leg** using the `/leg` skill (or craft guidance manually)
   - Read the flight spec, flight log, and relevant source code
   - Create the leg artifact with acceptance criteria
2. **Spawn a Developer agent for design review** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: the target project
   - Provide the "Review Leg Design" prompt from PROMPTS.md
   - The Developer reads the leg artifact and cross-references against actual codebase state
   - The Developer provides a structured assessment: approve, approve with changes, or needs rework
3. **Incorporate feedback** — update the leg artifact to address any issues raised
   - High-severity issues: must fix before proceeding
   - Medium-severity issues: fix unless there's a clear reason not to
   - Low-severity issues and suggestions: apply at discretion
4. **Re-review if substantive changes were made** — spawn another Developer for a second pass
   - Skip if only minor/cosmetic fixes were applied
   - If the second review raises new high-severity issues, fix and re-review once more
   - **Max 2 design review cycles** — if issues persist after 2 rounds, escalate to human
5. **Signal `[HANDOFF:review-needed]`** when the leg design is finalized

### 2b: Leg Implementation

**NEVER implement code directly.** Spawn a Developer agent via the Task tool.

1. **Spawn a Developer agent** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: the target project
   - Provide the Developer prompt from PROMPTS.md
   - The Developer reads the leg artifact, implements to acceptance criteria, updates flight log
   - The Developer signals `[HANDOFF:review-needed]` when done — do NOT let it commit
2. **Spawn a Reviewer agent** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: the target project
   - Provide the Reviewer prompt from PROMPTS.md
   - The Reviewer evaluates ALL uncommitted changes against acceptance criteria and code quality
   - The Reviewer signals `[HANDOFF:confirmed]` or lists issues with severity
3. **If issues found**, spawn a new Developer agent to fix them
   - Provide the fix prompt from PROMPTS.md with the Reviewer's feedback
   - Loop review/fix until the Reviewer confirms
4. **Spawn the Developer agent to commit** after review passes
   - Provide the commit prompt from PROMPTS.md
   - The commit must include code changes, updated flight log, and updated leg status

### 2c: Leg Transition

After `[COMPLETE:leg]`:
1. Increment `legs_completed`
2. If more legs remain → return to 2a
3. If all legs complete → proceed to Phase 3

## Phase 3: Flight Completion

1. **Verify all legs** show `completed` status
2. **Verify flight log** has entries for all legs
3. **Verify documentation** — check that CLAUDE.md, README, and other project docs reflect any new commands, endpoints, configuration, or APIs introduced during the flight. If not, spawn a Developer agent to update them.
4. **Run flight debrief** using the `/flight-debrief` skill
5. **Update flight status** to `landed`
6. **Check off flight** in mission artifact
7. **Signal `[COMPLETE:flight]`**

## Architecture

Three Claude Code instances with distinct roles:

| Instance | Role | Working Directory | Model | Context |
|----------|------|-------------------|-------|---------|
| Mission Control (you) | Project management — legs, artifacts, orchestration | mission-control/ | Opus or Sonnet | Entire flight |
| Developer | Implementation — code, tests, docs | target project/ | Sonnet | One leg, then clear |
| Reviewer | Code review — quality, correctness, criteria | target project/ | Sonnet | One review, then clear |

**Separation is mandatory.** The Developer and Reviewer run in the target project and load its CLAUDE.md and conventions. The Reviewer has no knowledge of the Developer's reasoning — only the resulting changes. This provides objective review.

**Model selection:** Use Sonnet for Developer and Reviewer. MC may use Opus for complex planning. Never use Opus for the Reviewer.

## Handoff Signals

Emit on their own line at the end of a response:

| Signal | Meaning |
|--------|---------|
| `[HANDOFF:review-needed]` | Artifact/code ready for review |
| `[HANDOFF:confirmed]` | Review passed, proceed |
| `[BLOCKED:reason]` | Cannot proceed, needs resolution |
| `[COMPLETE:leg]` | Leg finished and committed |
| `[COMPLETE:flight]` | Flight landed |

## Git Workflow

| Event | Action |
|-------|--------|
| Flight start | Create branch: `flight/{number}-{slug}` |
| First leg complete | Open draft PR |
| Each leg complete | Commit code + artifacts with leg reference |
| Flight landed | Mark PR ready for review |

Commit message format:
```
leg/{number}: {description}

Flight: {flight-number}
Mission: {mission-number}
```

## Error Handling

| Situation | Action |
|-----------|--------|
| Developer agent fails mid-leg | Spawn new Developer with context of what failed |
| Design review loops > 2 times | Escalate to human with unresolved design issues |
| Code review loops > 3 times | Escalate to human |
| Leg marked blocked | Escalate to human with blocker details |
| Artifact discrepancy | Remediate before proceeding |
| Off the rails | Roll back to last leg commit, escalate |
