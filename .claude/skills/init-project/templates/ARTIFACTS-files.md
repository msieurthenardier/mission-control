# Artifact System: Filesystem

This project stores Flight Control artifacts as markdown files in the repository.

## Directory Structure

```
{target-project}/
├── missions/
│   └── {NN}-{mission-slug}/
│       ├── mission.md
│       ├── mission-debrief.md
│       └── flights/
│           └── {NN}-{flight-slug}/
│               ├── flight.md
│               ├── flight-log.md
│               ├── flight-briefing.md
│               ├── flight-debrief.md
│               └── legs/
│                   └── {NN}-{leg-slug}.md
├── maintenance/
│   └── {YYYY-MM-DD}.md
└── tests/
    └── behavior/
        ├── {slug}.md                       ← behavior-test spec (committed)
        └── {slug}/runs/
            └── {YYYY-MM-DD-HH-MM-SS}.md    ← run log (committed)

# Evidence directory lives at an ephemeral path OUTSIDE the project tree:
#   /tmp/behavior-tests/{project-slug}/{slug}/{YYYY-MM-DD-HH-MM-SS}/
# Never written into tests/behavior/. Holds screenshots, snapshot dumps,
# eval JSON, log captures. Local-only; cheap to regenerate by re-running.
# Two reasons: (a) PII risk in screenshots/snapshots, (b) repo bloat.
```

## Naming Conventions

- **Slugs**: Lowercase, kebab-case, derived from title (e.g., "User Authentication" → `user-authentication`)
- **Sequence numbers**: Missions, flights, and legs use two-digit prefixes (`01`, `02`, etc.) for ordering

---

## Core Artifacts

### Mission

| Property | Value |
|----------|-------|
| Location | `missions/{NN}-{slug}/mission.md` |
| Created | During mission planning |
| Updated | Until status changes to `active` |

**Format:**

```markdown
# Mission: {Title}

**Status**: planning | active | completed | aborted

## Outcome
What success looks like in human terms.

## Context
Why this mission matters now. Background information.

## Success Criteria
- [ ] Criterion 1 (observable, binary)
- [ ] Criterion 2
- [ ] Criterion 3

## Stakeholders
Who cares about this outcome and why.

## Constraints
Non-negotiable boundaries.

## Environment Requirements
- Development environment (devcontainer, local toolchain, cloud IDE)
- Runtime requirements (GUI, audio hardware, network access)
- Special tooling (Docker, specific CLI versions)

## Open Questions
Unknowns that need resolution during execution.

## Known Issues
Emergent blockers and issues discovered during execution. Add items here as flights surface problems that affect the broader mission — things not anticipated during planning but visible at the mission level.

- [ ] {Issue description} — discovered in Flight {N}, affects {scope}

## Flights

> **Note:** These are tentative suggestions, not commitments. Flights are planned and created one at a time as work progresses. This list will evolve based on discoveries during implementation.

- [ ] Flight 1: {description}
- [ ] Flight 2: {description}
- [ ] Flight N *(optional)*: Alignment — vibe coding session for creative collaboration and hands-on adjustments
```

---

### Flight

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{NN}-{slug}/flight.md` |
| Created | During flight planning |
| Updated | Until status changes to `in-flight` |

**Format:**

```markdown
# Flight: {Title}

**Status**: planning | ready | in-flight | landed | completed | aborted
**Mission**: [{Mission Title}](../../mission.md)

## Contributing to Criteria
- [ ] {Relevant success criterion 1}
- [ ] {Relevant success criterion 2}

---

## Pre-Flight

### Objective
What this flight accomplishes (one paragraph).

### Open Questions
- [ ] Question needing resolution
- [x] Resolved question → see Design Decisions

### Design Decisions

**{Decision Title}**: {Choice made}
- Rationale: Why this choice
- Trade-off: What we're giving up

### Prerequisites
- [ ] {What must be true before execution}

### Pre-Flight Checklist
- [ ] All open questions resolved
- [ ] Design decisions documented
- [ ] Prerequisites verified
- [ ] Validation approach defined
- [ ] Legs defined

---

## In-Flight

### Technical Approach
How the objective will be achieved.

### Checkpoints
- [ ] {Milestone 1}
- [ ] {Milestone 2}

### Adaptation Criteria

**Divert if**:
- {Condition requiring re-planning}

**Acceptable variations**:
- {Minor changes that don't require diversion}

### Legs

> **Note:** These are tentative suggestions, not commitments. Legs are planned and created one at a time as the flight progresses. This list will evolve based on discoveries during implementation.

- [ ] `{leg-slug}` - {Brief description}
- [ ] `{leg-slug}` - {Brief description}
- [ ] `hat-and-alignment` *(optional)* - Guided HAT (human acceptance test) session with iterative fixes

---

## Post-Flight

### Completion Checklist
- [ ] All legs completed
- [ ] Code merged
- [ ] Tests passing
- [ ] Documentation updated

### Verification
How to confirm the flight achieved its objective.
```

---

### Leg

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/legs/{NN}-{slug}.md` |
| Created | Before leg execution |
| Updated | Never once `in-flight` (immutable) |

**Format:**

```markdown
# Leg: {slug}

**Status**: planning | ready | in-flight | landed | completed | aborted
**Flight**: [{Flight Title}](../flight.md)

## Objective
Single sentence: what this leg accomplishes.

## Context
- Relevant design decisions from the flight
- How this fits into the broader technical approach
- Key learnings from prior legs (from flight log)

## Inputs
What exists before this leg runs:
- Files that must exist
- State that must be true

## Outputs
What exists after this leg completes:
- Files created or modified
- State changes

## Acceptance Criteria
- [ ] Criterion 1 (specific, observable)
- [ ] Criterion 2
- [ ] Criterion 3

## Verification Steps
How to confirm each criterion is met:
- {Command or manual check for criterion 1}
- {Command or manual check for criterion 2}

## Implementation Guidance

1. **{First step}**
   - Details about what to do

2. **{Second step}**
   - Details

## Edge Cases
- **{Edge case 1}**: How to handle

## Files Affected
- `path/to/file.ext` - {What changes}

---

## Post-Completion Checklist

**Complete ALL steps before signaling `[COMPLETE:leg]`:**

- [ ] All acceptance criteria verified
- [ ] Tests passing
- [ ] Update flight-log.md with leg progress entry
- [ ] Set this leg's status to `completed` (in this file's header)
- [ ] Check off this leg in flight.md
- [ ] If final leg of flight:
  - [ ] Update flight.md status to `landed`
  - [ ] Check off flight in mission.md
- [ ] Commit all changes together (code + artifacts)
```

---

## Supporting Artifacts

### Flight Log

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/flight-log.md` |
| Created | When flight is created |
| Updated | Continuously during execution (append-only) |

**Format:**

```markdown
# Flight Log: {Flight Title}

**Flight**: [{Flight Title}](flight.md)

## Summary
Brief overview of execution status and key outcomes.

---

## Leg Progress

### {Leg Name}
**Status**: completed | landed | in-flight | aborted
**Started**: {timestamp}
**Completed**: {timestamp}

#### Changes Made
- {Summary of what was implemented}

#### Notes
{Observations during execution}

---

## Decisions
Runtime decisions not in original plan.

### {Decision Title}
**Context**: Why needed
**Decision**: What was chosen
**Impact**: Effect on flight or future legs

---

## Deviations
Departures from planned approach.

### {Deviation Title}
**Planned**: What the flight specified
**Actual**: What was done instead
**Reason**: Why the deviation was necessary

---

## Anomalies
Unexpected issues encountered.

### {Anomaly Title}
**Observed**: What happened
**Severity**: blocking | degraded | cosmetic
**Resolution**: How handled or "unresolved"

---

## Session Notes
Chronological notes from work sessions.
```

---

### Flight Briefing

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/flight-briefing.md` |
| Created | Before flight execution begins |
| Purpose | Pre-flight summary for crew alignment |

**Format:**

```markdown
# Flight Briefing: {Flight Title}

**Date**: {briefing date}
**Flight**: [{Flight Title}](flight.md)
**Status**: Flight is ready for execution

## Mission Context
{Brief reminder of mission outcome and how this flight contributes}

## Objective
{What this flight will accomplish}

## Key Decisions
{Summary of critical design decisions crew should know}

## Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| {risk} | {mitigation} |

## Legs Overview
1. `{leg-slug}` - {description} - {estimated complexity}
2. `{leg-slug}` - {description} - {estimated complexity}

## Environment Requirements
{Any special setup needed before starting}

## Success Criteria
{How we'll know the flight succeeded}
```

---

### Flight Debrief

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/flight-debrief.md` |
| Created | After flight lands or diverts |
| Purpose | Post-flight analysis and lessons learned |

**Format:**

```markdown
# Flight Debrief: {Flight Title}

**Date**: {debrief date}
**Flight**: [{Flight Title}](flight.md)
**Status**: {landed | aborted}
**Duration**: {start} - {end}
**Legs Completed**: {X of Y}

## Outcome Assessment

### Objectives Achieved
{What the flight accomplished}

### Mission Criteria Advanced
{Which success criteria this flight contributed to}

## What Went Well
{Specific things that worked effectively}

## What Could Be Improved

### Process
- {Recommendations for flight execution}

### Technical
- {Code quality, architecture, debt}

### Documentation
- {Gaps identified}

## Deviations and Lessons Learned

| Deviation | Reason | Standardize? |
|-----------|--------|--------------|
| {what changed} | {why} | {yes/no} |

## Key Learnings
{Insights for future flights}

## Recommendations
1. {Most impactful recommendation}
2. {Second recommendation}
3. {Third recommendation}

## Action Items
- [ ] {Immediate actions}
- [ ] {Near-term improvements}
```

---

### Mission Debrief

| Property | Value |
|----------|-------|
| Location | `missions/{NN}-{mission}/mission-debrief.md` |
| Created | After mission completes or aborts |
| Purpose | Post-mission retrospective and methodology improvements |

**Format:**

```markdown
# Mission Debrief: {Mission Title}

**Date**: {debrief date}
**Mission**: [{Mission Title}](mission.md)
**Status**: {completed | aborted}
**Duration**: {start} - {end}
**Flights Completed**: {X of Y}

## Outcome Assessment

### Success Criteria Results
| Criterion | Status | Notes |
|-----------|--------|-------|
| {criterion} | {met/not met} | {notes} |

### Overall Outcome
{Did we achieve what we set out to do?}

## Flight Summary
| Flight | Status | Key Outcome |
|--------|--------|-------------|
| {flight} | {landed/aborted} | {outcome} |

## What Went Well
{Effective patterns and successes}

## What Could Be Improved
{Process, planning, execution improvements}

## Lessons Learned
{Insights to carry forward}

## Methodology Feedback
{Improvements to Flight Control process itself}

## Action Items
- [ ] {Follow-up work}
- [ ] {Process improvements}
```

---

### Maintenance Report

| Property | Value |
|----------|-------|
| Location | `maintenance/{YYYY-MM-DD}.md` |
| Created | After a mission or ad-hoc, during routine maintenance |
| Purpose | Codebase health assessment and maintenance recommendation |

**Format:**

```markdown
# Maintenance Report: {YYYY-MM-DD}

**Date**: {report date}
**Triggered by**: [{Mission Title}](missions/{NN}-{slug}/mission.md) *(optional — omit if ad-hoc)*
**Assessment**: {Flight Ready | Maintenance Required}

## Categories Inspected
{Numbered list of categories that were checked}

## Executive Summary
{2-3 sentence overview of codebase health and key findings}

## Findings by Category

### Category {N}: {Name}

| # | Finding | Severity | New/Known | Recommendation |
|---|---------|----------|-----------|----------------|
| {n} | {title} | {severity} | {new/known} | {recommendation} |

**Details:**
{Per-finding evidence with file paths and line numbers}

## Severity Summary

| Severity | Count |
|----------|-------|
| Critical | {N} |
| Action Required | {N} |
| Advisory | {N} |
| Pass | {N} |

## Known Debt Carried Forward
{Debt items from debriefs that were acknowledged but not addressed, or "None — no prior debt context"}

## Recommendations
1. {Most impactful recommendation}
2. {Second recommendation}
3. {Third recommendation}

## Maintenance Mission
{Link to scaffolded mission if created, or "Not required — codebase is flight ready"}
```

---

### Behavior Test — Spec

| Property | Value |
|----------|-------|
| Location | `tests/behavior/{slug}.md` |
| Created | Inline during planning conversations (flight, leg, mission, debrief, maintenance). See `.claude/skills/behavior-test/AUTHORING.md` on the mission-control side. |
| Updated | When the spec drifts from observed system behavior |
| Purpose | Re-runnable, AI-driven, multi-step acceptance test against real UI / API / shell / filesystem |
| Run via | `/behavior-test {slug}` |

The run skill executes tests using the **Witnessed** verification pattern — every action is judged by an independent Validator agent. The pattern guarantees that the agent that did the work is never the same agent that decides whether the work was correct.

**Format:**

```markdown
# Behavior Test: {Title}

**Slug**: `{slug}`
**Status**: draft | active | archived
**Created**: {YYYY-MM-DD}
**Last Run**: {YYYY-MM-DD-HH-MM-SS | never}
**Cache:** *(optional; default `cold`. Set to `warm` to skip cache-defeat — see AUTHORING.md "Cache mode".)*

## Intent
One paragraph: what this test verifies and why this paradigm fits (vs unit/integration tests).

## Preconditions
- Environment / fixture state required before running.
- Each precondition is operator-checkable; the run skill confirms readiness before spawning agents.

## Observables Required
What kinds of observables the test reads — and which apparatus (MCP / tool) measures each. The Executor discovers apparatus by name pattern at run time.

- browser (DOM state, page content — measured via chrome-devtools, playwright, or similar)
- shell (stdout, stderr, exit code — measured via Bash)
- http (response status / body / headers — measured via curl via shell or dedicated MCP)
- filesystem (file contents, directory listings — measured via Read / Write / Bash)

## Steps

| # | Actions | Expected Results |
|---|---------|------------------|
| 1 | Navigate browser to `{url}`. Wait for `{element}`. Click `{element}`. | `{observable result}` — e.g., page loads, toggle is in expected state, etc. |
| 2 | (Setup row, no judgment) | (empty) |
| 3 | (Wait point, no actions) | Within `{timeout}`, `{observable result}`. |
| 4 | Multi-action: do X, then do Y, then do Z. | Multi-expectation: A is true AND B is true. |

**Row conventions:**
- One row = one logical checkpoint (may bundle multiple actions + multiple expected results).
- Actions and Expected Results are in plain English — human-performable.
- Empty Actions = wait point; the Executor idles while the Validator polls.
- Empty Expected Results = pure setup; the Validator skips judgment.
- Use `[a11y]` marker in Expected Results to flag accessibility-relevant checks (picked up by the optional Accessibility Validator).

## Out of Scope
What this test does NOT verify (link related tests).

## Variants (optional)
Parametrized re-runs with different inputs.
```

---

### Behavior Test — Run Log

| Property | Value |
|----------|-------|
| Location | `tests/behavior/{slug}/runs/{YYYY-MM-DD-HH-MM-SS}.md` |
| Created | At the end of each `/behavior-test {slug}` invocation |
| Purpose | Per-run record: verdict, per-step results, Executor + Validator trace, evidence references |

**Format:**

```markdown
# Behavior Test Run: {slug} — {timestamp}

**Spec**: [tests/behavior/{slug}.md](../{slug}.md)
**Status**: pass | fail | partial | aborted
**Started**: {iso8601}
**Completed**: {iso8601}
**Duration**: {hh:mm:ss}
**Executor**: {sub-agent id}
**Validator**: {sub-agent id}

## Summary
{n_pass} / {n_total} steps passed. {n_fail} failed; {n_inconclusive} inconclusive.

## Step Results

### Step {N} — {PASS | FAIL | INCONCLUSIVE | SKIPPED}
- **Actions taken**: {executor's report of what was performed}
- **Raw state**: {one-line summary or excerpt}
- **Expected**: {verbatim from spec}
- **Verdict**: {pass/fail/inconclusive} — {validator's reasoning}
- **Evidence**: [{relative path}](./{ts}/{filename})
- **Validator notes**: {optional}
- **Operator decision**: {continued | halted | rerun-step} (only when step failed)

## Orchestrator Notes
{Decisions made during the run: model preferences, specialized validators spawned, operator interventions.}

## Closing Summaries

### Executor closing
{Executor's freeform closing summary — anomalies, environment hiccups.}

### Validator closing
{Validator's freeform closing summary — spec-quality observations, patterns of failure.}

## Operator Notes
{Post-run reflections.}
```

**Evidence directory**: `/tmp/behavior-tests/{project-slug}/{slug}/{ts}/` — outside the project tree, never committed. Holds screenshots, snapshot dumps, response bodies, file captures referenced by the run log. Skipping commit is deliberate: evidence routinely captures operator-visible UI (member lists, real-name peers, profile chrome) and would be repo bloat. Re-derive by re-running the spec.

---

## State Tracking

States are tracked in the frontmatter or status field of each artifact:

| Artifact | States |
|----------|--------|
| Mission | `planning` → `active` → `completed` (or `aborted`) |
| Flight | `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`) |
| Leg | `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`) |
| Behavior Test Spec | `draft` → `active` → `archived` |
| Behavior Test Run | `pass` \| `fail` \| `partial` \| `aborted` (terminal; never edited after the run completes) |

## Conventions

- **Immutability**: Never modify legs once `in-flight`; create new ones instead
- **Append-only logs**: Flight logs are append-only during execution
- **Flight briefings**: Created before execution, not modified after
- **Debriefs**: Created after completion, may be updated with follow-up notes
- **Mission as briefing**: The mission.md document serves as both definition and briefing (no separate mission-briefing.md)
