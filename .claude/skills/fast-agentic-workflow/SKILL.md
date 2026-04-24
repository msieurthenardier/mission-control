---
name: fast-agentic-workflow
description: Streamlined flight execution. Developer implements the entire flight in one pass, review happens once, leg artifacts are generated retroactively.
---

# Fast Agentic Workflow

Streamlined flight execution for when per-leg orchestration overhead isn't justified. The Developer implements the entire flight in a single session, one review covers all changes, and leg artifacts are generated retroactively.

## Prerequisites

- Project must be initialized with `/init-project` (`.flightops/ARTIFACTS.md` must exist)
- A mission must exist and be `active`
- A flight must exist and be `ready` or `in-flight`

## Invocation

```
/fast-agentic-workflow flight {number} for {project-slug} mission {number}
```

Example: `/fast-agentic-workflow flight 03 for epipen mission 04`

## Phase 1: Context Loading

1. **Read `projects.md`** to find the target project's path
2. **Read `{target-project}/.flightops/ARTIFACTS.md`** for artifact locations
3. **Read `{target-project}/.flightops/agent-crews/leg-execution.md`** for project crew definitions, interaction protocol, and prompts (fall back to defaults at `.claude/skills/init-project/defaults/agent-crews/leg-execution.md`)
   - **Validate structure**: The phase file MUST contain `## Crew`, `## Interaction Protocol`, and `## Prompts` sections. Each prompt subsection MUST have a fenced code block.
   - **If the file exists but is malformed**: STOP. Tell the user: "Phase file `leg-execution.md` is missing required sections. Either fix it manually or re-run `/init-project` to reset to defaults." Do NOT improvise missing prompts — halt and get the file fixed.
4. **Read the mission artifact** — outcomes, success criteria, constraints
5. **Read the flight artifact** — objective, design decisions, leg list
6. **Read the flight log** — ground truth from prior execution
7. **Read git strategy** from `{target-project}/.flightops/ARTIFACTS.md` `## Git Workflow` section. Default to `branch` if the section is absent.
8. **Set `{working-directory}`** — `branch`: the target project root; `worktree`: the worktree path (see Git Workflow section below)

**Mark flight as in-flight**: After loading the flight artifact, if the flight status is `ready`, update it to `in-flight` before proceeding. If already `in-flight`, leave it as-is.

## Phase 2: Full-Flight Implementation

**NEVER implement code directly.** Spawn a Developer agent via the Task tool.

1. **Spawn a Developer agent** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: `{working-directory}`
   - Provide the "Implement" prompt from the leg-execution phase file's Prompts section
   - Include the full flight spec — objective, all legs with their descriptions, design decisions, and constraints
   - The Developer implements the entire flight to acceptance criteria
   - When done, the Developer updates the flight log and signals `[HANDOFF:review-needed]` — do NOT let it commit
2. **Spawn a Reviewer agent** (Task tool, `subagent_type: "general-purpose"`)
   - Working directory: `{working-directory}`
   - Provide the "Review" prompt from the leg-execution phase file's Prompts section
   - The Reviewer evaluates ALL uncommitted changes against the flight's acceptance criteria and code quality
   - The Reviewer signals `[HANDOFF:confirmed]` or lists issues with severity
3. **If issues found**, spawn a new Developer agent to fix them
   - Provide the "Fix Review Issues" prompt from the leg-execution phase file with the Reviewer's feedback
   - Loop review/fix until the Reviewer confirms
4. **Commit** after review passes — include all code changes and updated flight log

## Phase 3: Retroactive Leg Documentation

After the implementation is committed, generate leg artifacts to record what was done:

1. **For each leg in the flight spec**, create a leg artifact using the `/leg` skill (if the Skill tool is unavailable, read `.claude/skills/leg/SKILL.md` and follow the workflow directly)
   - Base the acceptance criteria on what was actually implemented, not on pre-implementation plans
   - Mark each leg status as `completed`
2. **Update the flight log** with leg entries if the Developer didn't already cover them individually
3. **Commit** the leg artifacts

## Phase 4: Flight Completion

1. **Verify flight log** has entries covering all work done
2. **Verify documentation** — check that CLAUDE.md, README, and other project docs reflect any new commands, endpoints, configuration, or APIs introduced during the flight. If not, spawn a Developer agent to update them.
3. **Update flight status** to `landed`
4. **Check off flight** in mission artifact
5. **Manage PR**:
   - Open a PR with the leg checklist in the body (see PR Body Format below), all legs checked off
   - Mark PR ready for review
6. **Clean up worktree** (worktree strategy only) — run `git worktree remove` after the PR is marked ready for review
7. **Signal `[COMPLETE:flight]`**

The flight debrief is a separate step run via `/flight-debrief` after the flight lands. The debrief transitions the flight to `completed`.

## Architecture

The Flight Director (you) orchestrates according to this skill. Project crew composition, roles, models, and prompts are defined in `{target-project}/.flightops/agent-crews/leg-execution.md`.

**Separation is mandatory.** Project crew agents run in the target project and load its CLAUDE.md and conventions. The Reviewer has no knowledge of the Developer's reasoning — only the resulting changes. This provides objective review.

**Model selection:** Follow the model preferences in the phase file. MC may use Opus for complex planning. Never use Opus for the Reviewer.

## Handoff Signals

Signals are part of the Flight Control methodology and are NOT configurable per-project. All crew agents must use these exact signals:

| Signal | Emitted By | Meaning |
|--------|-----------|---------|
| `[HANDOFF:review-needed]` | Developer | Code ready for review |
| `[HANDOFF:confirmed]` | Reviewer | Review passed |
| `[BLOCKED:reason]` | Any crew agent | Cannot proceed, needs resolution |
| `[COMPLETE:flight]` | Flight Director | Flight landed |

## Flight Director Decision Log

The Flight Director must maintain transparency about its own decisions. After each major orchestration step, log what happened and why in the flight log under a `### Flight Director Notes` subsection:

1. **Phase file loading** — Record which phase file was loaded (project or default fallback) and what crew was extracted
2. **Agent spawning** — Record which agent was spawned, with what prompt, and what model
3. **Review cycle decisions** — When incorporating feedback, note what was accepted/rejected and why
4. **Escalation decisions** — When choosing between "fix and re-review" vs "escalate to human," note the reasoning

## Git Workflow

### Strategy Selection

Read the `## Git Workflow` section from `{target-project}/.flightops/ARTIFACTS.md`. The `Strategy` property determines which workflow to use. If the section is absent, default to `branch`.

### Shared Elements

Both strategies use the same branch naming, commit format, PR lifecycle, and PR body format.

**Branch naming**: `flight/{number}-{slug}`

**Commit message format:**
```
flight/{number}: {description}

Mission: {mission-number}
```

**PR lifecycle:**

| Event | Action |
|-------|--------|
| Flight complete | Open PR with all legs checked off, mark ready for review |

**PR body format:**

```markdown
## {Flight Title}

{Flight objective — one paragraph}

**Mission**: {Mission Title}

## Legs

- [x] `{leg-slug}` — {brief description}
- [x] `{leg-slug}` — {brief description}
```

### Strategy: Branch

The default single-checkout workflow. One flight at a time per working copy.

| Step | Command |
|------|---------|
| Flight start | `git checkout -b flight/{number}-{slug}` |
| Set `{working-directory}` | Target project root |
| Agents work in | Project root |
| Flight landed | PR marked ready for review |

### Strategy: Worktree

Worktree isolation enables parallel flights on a single repo clone.

| Step | Command |
|------|---------|
| Flight start | `git worktree add .worktrees/flight-{number}-{slug} -b flight/{number}-{slug}` |
| Set `{working-directory}` | `.worktrees/flight-{number}-{slug}` |
| Orchestrator stays on | Main branch (does not checkout the flight branch) |
| Agents work in | Worktree path |
| Flight landed | PR marked ready for review, then `git worktree remove .worktrees/flight-{number}-{slug}` |

**Note:** The `.worktrees/` directory must be in `.gitignore` when using this strategy.

## Error Handling

| Situation | Action |
|-----------|--------|
| Developer agent fails mid-flight | Spawn new Developer with context of what failed |
| Code review loops > 3 times | Escalate to human |
| Artifact discrepancy | Remediate before proceeding |
| Off the rails | Roll back to last commit, escalate |
| Stale worktree (worktree strategy) | Run `git worktree prune`, recreate if needed |
| Agent hangs on tests | Kill the agent, spawn new Developer to isolate and fix hanging tests |
