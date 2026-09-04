---
name: agentic-workflow
description: Active orchestrator for multi-agent flight execution. Drives leg design per leg, then batches implementation across all autonomous legs, with a single code review and commit at the end of the flight.
---

# Agentic Workflow

Orchestrate multi-agent flight execution. You drive the full leg cycle — designing legs, spawning Developer and Reviewer agents, and managing git workflow — for a target project's flight. Leg design review is risk-tiered (high-risk legs get a per-leg design review; low-risk legs go straight to implementation), and code review and commit are deferred until after the last autonomous leg completes. This eliminates per-leg review/commit overhead while keeping the same leg design and implementation structure.

## Prerequisites

- Project must be initialized with `/init-project` (`.flightops/ARTIFACTS.md` must exist)
- A mission must exist and be `active`
- A flight must exist and be `ready` or `in-flight`

## Invocation

```
/agentic-workflow flight {number} for {project-slug} mission {number}
```

Example: `/agentic-workflow flight 03 for epipen mission 04`

## Phase 1: Context Loading

1. **Read `projects.md`** to find the target project's path
2. **Read `{target-project}/.flightops/ARTIFACTS.md`** for how this project handles each artifact — storage location, format, and any actions the project defines at create and transition time (e.g., transitioning a ticket, posting a notification). Honor these when you or a spawned agent moves an artifact through its lifecycle.
3. **Read `{target-project}/.flightops/agent-crews/leg-execution.md`** for project crew definitions, interaction protocol, and prompts (fall back to defaults at `.claude/skills/init-project/defaults/agent-crews/leg-execution.md`)
   - **Validate structure**: The phase file MUST contain `## Crew`, `## Interaction Protocol`, and `## Prompts` sections. Each prompt subsection MUST have a fenced code block.
   - **If the file exists but is malformed**: STOP. Tell the user: "Phase file `leg-execution.md` is missing required sections. Either fix it manually or re-run `/init-project` to reset to defaults." Do NOT improvise missing prompts — halt and get the file fixed.
4. **Read the mission artifact** — outcomes, success criteria, constraints
5. **Read the flight artifact** — objective, design decisions, leg list
6. **Read the flight log** — ground truth from prior execution
7. **Count total legs** from the flight spec — track progress throughout
8. **Determine starting point** — which leg is next based on flight log and leg statuses

**Mark flight as in-flight**: After loading the flight artifact, if the flight status is `ready`, update it to `in-flight` before proceeding, performing any transition-time handling `.flightops/ARTIFACTS.md` defines for that transition (default: none). If already `in-flight`, leave it as-is.

If resuming a flight already in progress, verify state consistency:
- Flight log entries must match leg statuses
- If discrepancies exist, remediate before proceeding

## Phase 2: Leg Cycle

Repeat for each leg in the flight.

**Out-of-scope defects found mid-flight**: when you or a Developer finds something broken that this flight isn't chartered to fix, do not fold it into the leg in hand — that is how flights lose their shape. Log it as a squawk via the `/squawk` skill and defer it, noting the id in the flight log. Two exceptions: a `grounding` defect sitting directly in this flight's path is completed before the flight continues; and anything that fails the squawk qualification gate (needs design, changes a shared interface or schema) is raised to the operator as a possible new flight instead.

**Mid-execution scope changes**: if the work in this flight stops serving its original purpose (operator pivots, prior assumptions invalidated), don't rewrite the mission/flight artifacts in place. Preserve the original framing as commentary, record the pivot decision in the flight-log Flight Director Notes with rationale, and treat the new framing as the live spec going forward. If the pivot supersedes content in an upstream artifact (maintenance report, prior debrief), annotate at the artifact header rather than rewriting the body — inspection records are snapshots, not living plans.

### 2a: Leg Design

1. **Design the leg** — the Flight Director does this directly (artifact only, never code):
   - **Gather ground truth.** Re-read the flight log for actual outcomes, deviations, anomalies, environment details, and decisions from prior legs. Identify this leg's scope, its dependencies on prior legs, and environment constraints (container vs host, user context, required env vars).
   - **Read the code the leg will touch.** Note existing patterns and conventions, the state that exists before the leg and must exist after, and edge cases the implementing agent must handle.
   - **Run the risk checks** (each of these has bitten a past flight):
     - *Schema changes*: migration creation AND execution belong in the same leg — a schema defined but never migrated is a gap.
     - *Reachability*: for every state, lifecycle value, or condition an acceptance criterion depends on, verify no lower layer forecloses it — FK `ON DELETE` behaviors, constraints, caches, fallback handlers that silently mask the state, platform or configuration limits (a window minimum, a size cap, a feature flag, a permission tier) that make the condition impossible to reach. Tests that pin behavior the new design breaks must be inverted or renamed in this leg (rename over delete-and-readd, so git blame documents the intent shift).
     - *Cache freshness*: for every cache the leg reads or populates, declare its source of truth, exactly one rebuild trigger, and the maximum staleness acceptable to the user — then confirm every user action that mutates the source invalidates the cache. A cache that "works fine" is not the same as one that reflects current config.
     - *Interface changes*: grep for consumers of any changed symbol; if tests or out-of-scope source call it, decide explicitly whether updating them is part of this leg.
   - **Write the leg artifact** and persist it per `.flightops/ARTIFACTS.md`, including any create-time handling the project defines. It needs: an objective stating exactly what the leg accomplishes; acceptance criteria that are binary, observable, and complete (a criterion only verifiable against the running system references a behavior-test slug instead — see Behavior Tests below); and verification steps saying exactly how to confirm each criterion.
   - **Cite code durably and verify citations.** Prefer `file:symbol` or `file:line — "snippet"` over bare line numbers. Before marking the leg `ready`, check every citation against current code: repair drifted line numbers, flag vanished content for human review (the gap may be fixed — or the leg obsolete), and append a short Citation Audit note to the artifact.
   - **Size for decisions and risk, not effort.** A leg is a coherent feature slice carrying its own tests and doc updates. Split only where a mid-leg human decision or a hard-to-reverse step needs its own checkpoint — never by task type (standalone tests-only or docs-only legs are a smell).
   - **Legs are immutable once `in-flight`.** If requirements change mid-implementation, mark the leg `aborted` (changes rolled back) and create a new one.
2. **Risk-tier the leg — out loud.** Record the call and its rationale in the flight log's Flight Director Notes.
   - **High-risk** — any of: schema or migration changes; shared-interface changes with existing consumers; state-machine or lifecycle changes; cache/freshness behavior; security-sensitive surface; or the leg reverses/contradicts something in the flight spec or a prior leg's outcome → run the design review (steps 3-4)
   - **Low-risk** — additive, single-surface work within established codebase patterns → skip steps 3-4 and proceed; the flight-end Reviewer (Phase 2d) still covers the resulting code
   - When in doubt, tier high — the review is cheap relative to a wrong leg
3. **Spawn a Developer agent for design review** (high-risk legs only) (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: `{target-project}`
   - Provide the "Review Leg Design" prompt from the leg-execution phase file's Prompts section
   - The Developer reads the leg artifact and cross-references against actual codebase state
   - The Developer provides a structured assessment: approve, approve with changes, or needs rework
   - **Incorporate feedback** — update the leg artifact to address any issues raised
     - High-severity issues: must fix before proceeding
     - Medium-severity issues: fix unless there's a clear reason not to
     - Low-severity issues and suggestions: apply at discretion
4. **Re-review if substantive changes were made** — spawn another Developer for a second pass
   - Skip if only minor/cosmetic fixes were applied
   - If the second review raises new high-severity issues, fix and re-review once more
   - **Max 2 design review cycles** — if issues persist after 2 rounds, escalate to human
5. **Update leg status** to `ready`
6. **Signal `[HANDOFF:review-needed]`** when the leg design is finalized

### 2b: Leg Implementation

**NEVER implement code directly.** Spawn a Developer agent via the Task tool.

**Interactive/HAT legs**: If the leg is a HAT (human acceptance test), alignment, or other interactive leg (identified by slug like `hat-*`, `alignment-*`, or explicit marking in the flight spec), do NOT spawn agents to execute it autonomously. The human performs verification — the Flight Director guides them through it:
1. **Design the leg** normally (2a), but keep it lightweight — the acceptance criteria are verification steps, not implementation tasks
2. **Skip the autonomous implementation cycle** (no Developer/Reviewer agents)
3. **Guide the human through verification steps one at a time** — present a single step, wait for the human to perform it and report results, then proceed to the next step
4. **Fix issues inline** — if the human reports a failure, diagnose and fix it (spawning a Developer agent if code changes are needed), then re-verify that step before moving on
   - **Fix-vs-feature gate**: an operator request arising mid-HAT that adds new behavior (a FEATURE) is promoted to a scoped design review before implementation; only look-and-feel FIXES ride the inline protocol. The fix-vs-feature line is the Flight Director's call, made out loud.
   - **Multi-surface scope trigger**: even when classified as a look-and-feel fix, if the change spans more than one page/surface (e.g. it touches another internal page, the chrome, or main-process wiring beyond the surface under test), spawn a lightweight Developer design-review pass before the implementing spawn. Two missions of data show multi-surface "cosmetic" fixes routinely carry riders (unguarded inputs, cross-file wiring) that a review catches cheaply.
5. **Commit when all steps pass** — update artifacts and commit

**Standard (autonomous) legs**: Spawn a Developer agent — but do NOT review or commit after each leg.

1. **Spawn a Developer agent** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: `{target-project}`
   - Provide the "Implement" prompt from the leg-execution phase file's Prompts section
   - The Developer updates leg status to `in-flight`, implements to acceptance criteria
   - When done, the Developer updates leg status to `landed` and updates flight log — do NOT let it commit or signal `[HANDOFF:review-needed]`
   - In your spawn prompt, instruct the Developer that whenever it changes the leg's status, it must also perform any transition-time handling the project's `.flightops/ARTIFACTS.md` defines for that transition (default: none). State this directly in the prompt — don't assume the crew file carries it.

### 2c: Leg Transition

After the Developer completes a leg:
1. Increment `legs_completed`
2. If more autonomous legs remain → return to 2a
3. If this was the last autonomous leg → proceed to Phase 2d

### 2d: Flight Review and Commit

After all autonomous legs are implemented (all uncommitted):

1. **Spawn a Reviewer agent** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: `{target-project}`
   - Provide the "Review" prompt from the leg-execution phase file's Prompts section
   - The Reviewer evaluates ALL uncommitted changes against acceptance criteria and code quality
   - The Reviewer signals `[HANDOFF:confirmed]` or lists issues with severity
2. **If issues found**, spawn a new Developer agent to fix them
   - Provide the "Fix Review Issues" prompt from the leg-execution phase file with the Reviewer's feedback
   - Loop review/fix until the Reviewer confirms
3. **Commit** after review passes — include all code changes, updated flight log, and all leg statuses updated to `completed`
4. **Manage PR**: Open a draft PR with the leg checklist in the body (see PR Body Format below), all legs checked off

## Phase 3: Flight Completion

1. **Verify all legs** show `completed` status
2. **Verify flight log** has entries for all legs
3. **Verify documentation** — check that CLAUDE.md, README, and other project docs reflect any new commands, endpoints, configuration, or APIs introduced during the flight. If not, spawn a Developer agent to update them.
4. **Update flight status** to `landed`, performing any transition-time handling `.flightops/ARTIFACTS.md` defines for that transition (default: none)
5. **Check off flight** in mission artifact
6. **Signal `[COMPLETE:flight]`**

The flight debrief is a separate step run via `/flight-debrief` after the flight lands. The debrief transitions the flight to `completed`.

## Behavior Tests as Acceptance Verification

A flight (or a specific leg) may declare its acceptance criteria via a **behavior test** spec — a Zephyr-style two-column Action | Expected Result table, run via the `/behavior-test` skill with two live AI agents (Executor + Validator) using the Witnessed pattern. Behavior tests verify real-environment observation that doesn't fit unit/integration tests (UI flows, multi-component interactions, AI agent behavior).

**Where they fit in this workflow:**

- A leg authored during Phase 2a may reference a behavior-test slug instead of (or in addition to) inline verification steps — e.g., "Acceptance: `/behavior-test discord-engagement` passes."
- When the Flight Director reaches such a leg, run the test by invoking `/behavior-test {slug}` directly (not by spawning a Developer agent — the run skill orchestrates its own crew).
- The behavior-test's run log lands at the project's configured behavior-test run-log location (per ARTIFACTS.md), committed; evidence lives at an ephemeral path outside the project tree and is never committed (see the behavior-test skill's Evidence Handling). The leg's flight-log entry references the run log.
- A failing behavior test is an unmet acceptance criterion: **the leg does not land while the test fails.** Investigate, fix in a new commit (no amend), re-run. If the operator instead accepts the failure as a known issue, the leg may land with that disposition recorded in the flight-log entry alongside the run-log path — the flight debrief carries it forward.

**Authoring behavior-test specs**: specs are written inline during planning conversations (flight design, leg design), not via a dedicated skill. See `.claude/skills/behavior-test/AUTHORING.md` for the authoring guide (interview shape, spec format, common pitfalls). Format is canonical in the target project's `.flightops/ARTIFACTS.md`.

**Crew prompts** (Executor + Validator) live at `{target-project}/.flightops/agent-crews/behavior-tests-execution.md` — installed by `/init-project` and modifiable per project.

## Architecture

The Flight Director (you) orchestrates according to this skill. Project crew composition, roles, models, and prompts are defined in `{target-project}/.flightops/agent-crews/leg-execution.md`.

**Separation is mandatory.** Project crew agents run in the target project and load its CLAUDE.md and conventions. The Reviewer has no knowledge of the Developer's reasoning — only the resulting changes. This provides objective review.

**Model selection:** Follow the model preferences in the phase file. MC may use Opus for complex planning. Never use Opus for the Reviewer.

## Handoff Signals

Signals are part of the Flight Control methodology and are NOT configurable per-project. All crew agents must use these exact signals:

| Signal | Emitted By | Meaning |
|--------|-----------|---------|
| `[HANDOFF:review-needed]` | Developer | Code/artifact ready for review |
| `[HANDOFF:confirmed]` | Reviewer | Review passed |
| `[BLOCKED:reason]` | Any crew agent | Cannot proceed, needs resolution |
| `[BLOCKED:exceeds-squawk-scope]` | Developer | A squawk fix needs design work — revert and escalate (see `/squawk`) |
| `[COMPLETE:leg]` | Developer | Leg finished and committed |
| `[COMPLETE:squawk]` | Flight Director | Squawk(s) implemented, reviewed, and committed (see `/squawk`) |
| `[COMPLETE:flight]` | Flight Director | Flight landed |

## Flight Director Decision Log

Log orchestration decisions in the flight log under `### Flight Director Notes` — phase file loaded, agents spawned, review-cycle calls, escalations, signal interpretations. Anyone reading the log should understand not just what the crew did but why MC made the choices it did.

## Git Workflow

All agents work in the target project root on a feature branch created at flight start. Branch naming and commit message format follow the project's **Git Conventions** in `.flightops/ARTIFACTS.md` — create the flight branch per that scheme at flight start.

**PR lifecycle:**

| Event | Action |
|-------|--------|
| All legs complete | Open draft PR with all legs checked off |
| Flight landed | Mark PR ready for review |

**PR body format:**

```markdown
## {Flight Title}

{Flight objective — one paragraph}

**Mission**: {Mission Title}

## Legs

- [x] `{leg-slug}` — {brief description}
- [x] `{leg-slug}` — {brief description}
```

## Error Handling

| Situation | Action |
|-----------|--------|
| Developer agent fails mid-leg | Spawn new Developer with context of what failed |
| Design review loops > 2 times | Escalate to human with unresolved design issues |
| Code review loops > 3 times | Escalate to human |
| Leg marked aborted | Escalate to human with abort details |
| Artifact discrepancy | Remediate before proceeding |
| Off the rails | Roll back to last leg commit, escalate |
| Agent hangs on tests | Kill the agent, spawn new Developer to isolate and fix hanging tests |
