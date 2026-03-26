---
name: routine-maintenance
description: Codebase health assessment and maintenance recommendation. Use after a mission or ad-hoc to verify codebase is flight-ready or scaffold a maintenance mission.
---

# Routine Maintenance

Perform an exhaustive, aviation-style codebase inspection. Can be triggered after a mission completes or run ad-hoc at any time. Produces a findings report and optionally scaffolds a maintenance mission for significant issues.

## Prerequisites

- Project must be initialized with `/init-project` (`.flightops/ARTIFACTS.md` must exist)

## Workflow

### Phase 1: Context Loading

1. **Identify the target project**
   - Read `projects.md` to find the project's path

2. **Verify project is initialized**
   - Check if `{target-project}/.flightops/ARTIFACTS.md` exists
   - **If missing**: STOP and tell the user to run `/init-project` first
   - Do not proceed without the artifact configuration

3. **Read the artifact configuration**
   - Read `{target-project}/.flightops/ARTIFACTS.md` for artifact locations and formats

4. **Load prior maintenance reports (if any exist)**
   - Read previous reports in `maintenance/` to identify deferred findings from earlier cycles
   - Deferred findings are those documented in prior reports but not addressed by a maintenance mission
   - This ensures recurring issues are tracked across cycles rather than re-discovered as "new"

5. **Load mission and debrief documentation (if available)**
   - If a recent mission exists, read it for outcome, success criteria, and known issues
   - If a mission debrief exists, read it for lessons learned and action items
   - If flight debriefs exist, read them for per-flight technical debt and recommendations
   - This provides known-debt context so the inspection can distinguish new issues from acknowledged ones
   - If no mission context is available (ad-hoc run), proceed without known-debt context

6. **Identify project stack**
   - Read `README.md`, `CLAUDE.md`, and package files (`package.json`, `Cargo.toml`, `go.mod`, etc.)
   - Determine language, framework, test runner, linter, formatter, type checker, and dependency audit tool

### Phase 2: Category Scoping Interview

Categories 1–7 always apply to every project. Ask the user yes/no for optional categories:

> "Before I begin the inspection, a few quick questions:"
>
> 1. "Does this project have CI/CD pipelines?" → enables Category 8
> 2. "Does this project have deployments, databases, or environment-specific configs?" → enables Category 9
> 3. "Does this project have monitoring, metrics, or observability tooling?" → enables Category 10
>
> "Any specific areas of concern for this project?"

Record user responses and any areas of concern to pass to the Inspector.

### Phase 3: Automated Inspection

Read `{target-project}/.flightops/agent-crews/routine-maintenance.md` for crew definitions and prompts (fall back to defaults at `.claude/skills/init-project/defaults/agent-crews/routine-maintenance.md`).

**Validate structure**: The crew file MUST contain `## Crew`, `## Interaction Protocol`, and `## Prompts` sections with fenced code blocks. If the file exists but is malformed, STOP and tell the user: "Crew file `routine-maintenance.md` is missing required sections. Either fix it manually or re-run `/init-project` to reset to defaults."

#### Spawn Inspector

1. **Spawn an Inspector agent** in the target project context (Agent tool, `subagent_type: "general-purpose"`)
   - Provide the "Inspect Codebase" prompt from the crew file's Prompts section
   - Include: applicable category list (1–7 always, plus any enabled optional categories), project stack info, known debt from debriefs, and user's areas of concern
   - The Inspector performs **read-only** checks — it MUST NOT modify any files
   - The Inspector returns structured findings per category

**IMPORTANT**: The Inspector is strictly read-only. It may run test suites, linters, type checkers, and audit commands, but it must NEVER modify source files, configuration, or dependencies.

### Phase 4: Severity Assessment

#### Spawn Architect

1. **Spawn an Architect agent** with Inspector findings + debrief context if available (Agent tool, `subagent_type: "general-purpose"`)
   - Provide the "Assess Findings" prompt from the crew file's Prompts section
   - Include: Inspector's raw findings, known debt items (if available from debriefs)
   - The Architect assigns a final severity to each finding:

| Severity | Meaning |
|----------|---------|
| **Pass** | No issue found |
| **Advisory** | Minor issue, deferring is acceptable |
| **Action Required** | Should be addressed before next major work cycle |
| **Critical** | Blocks further work, immediate attention needed |

   - The Architect produces an overall assessment:
     - **Flight Ready** — All findings are Pass or Advisory
     - **Maintenance Required** — Any finding is Action Required or Critical

### Phase 5: Human Review and Scoping

Present findings grouped by severity (Critical first, then Action Required, Advisory, Pass):

> **Overall Assessment: {Flight Ready | Maintenance Required}**
>
> {Findings summary table}

Then ask:
1. "Do these findings match your sense of the codebase health?"
2. "Any findings to override or adjust severity?"

Apply any overrides the user requests.

#### Scope Selection

If the assessment is Maintenance Required, help the user choose a manageable scope rather than scaffolding everything. Present a recommended shortlist:

> **Recommended scope** (Critical items are always included):
>
> {Numbered list of Critical + top Action Required findings, capped at ~5-7 items}
>
> {Count} additional Action Required and {count} Advisory findings are documented in the report for a future cycle.
>
> "Want me to scaffold a maintenance mission for these items? You can add or remove findings from the list."

The goal is a mission that can land in a single focused session. All findings are captured in the report regardless — deferred items aren't lost, they'll surface again in the next maintenance cycle. This keeps maintenance approachable even when the backlog is large.

### Phase 6: Generate Maintenance Report

Create the maintenance report artifact at the location defined in `.flightops/ARTIFACTS.md` (typically `maintenance/YYYY-MM-DD.md`). If a report already exists for today's date, append a numeric suffix (e.g., `2026-03-26-2.md`).

**Report contents:**
- Title (date-based) and date
- Optional "Triggered by" link to the mission that prompted the inspection (if applicable)
- Overall assessment (Flight Ready / Maintenance Required)
- Categories inspected
- Executive summary
- Findings by category (each with severity, description, evidence, recommendation)
- Severity summary (counts per level)
- Known debt carried forward (from debriefs, acknowledged but not addressed)
- Recommendations

### Phase 7: Scaffold Maintenance Mission (conditional)

**Only if**: Overall assessment is Maintenance Required AND the user confirmed they want a maintenance mission. Only the findings the user selected in Phase 5 are scaffolded — deferred findings remain in the report for future cycles.

This phase produces the full artifact tree — mission, flights, and legs — so the maintenance work is ready for `/agentic-workflow` execution without running `/mission`, `/flight`, or `/leg` separately.

#### 7a. Mission

Scan existing `missions/` directories to determine the next sequence number `{NN}`. Create `missions/{NN}-maintenance/mission.md` using the standard mission format from `.flightops/ARTIFACTS.md`:
- **Status**: `planning`
- **Outcome**: "Resolve codebase health issues identified in maintenance report {YYYY-MM-DD}"
- **Context**: Link to the maintenance report in `maintenance/{YYYY-MM-DD}.md`
- **Success Criteria**: One criterion per selected finding
- **Flights**: List the flights from step 7b
- Populate all standard mission sections. Mark sections with no relevant content as "N/A" (e.g., Open Questions, Stakeholders).

#### 7b. Flights

Re-group the user's selected findings into flights. Use the Architect's recommended groupings as a starting point, but adjust for any findings the user removed or added during Phase 5 scoping. Typical groupings: one flight per category with actionable findings, or by technical area when findings from different categories affect the same subsystem.

Each flight gets its own directory with `flight.md` and `flight-log.md`. Use the standard formats from `.flightops/ARTIFACTS.md` with these maintenance-specific notes:

- **Status**: `ready` — maintenance flights skip the Pre-Flight phase (no open questions or design decisions to resolve for concrete fixes). Mark Pre-Flight Checklist items as N/A.
- **Mission**: Link back to the maintenance mission
- **Objective**: What this group of fixes accomplishes
- **Technical Approach**: Brief description of the fix strategy per finding
- **Legs**: List the legs from step 7c
- Populate all other standard flight sections. Mark sections with no relevant content as "N/A".

The `flight-log.md` is created empty (header only) — it will be populated during execution.

#### 7c. Legs

Each flight gets one leg per discrete fix. Create leg files using the standard format from `.flightops/ARTIFACTS.md` with these fields populated:

- **Status**: `ready`
- **Flight**: Link back to the flight
- **Objective**: Fix one specific finding (reference the finding number from the report)
- **Context**: Link to the maintenance report finding and the Architect's recommendation
- **Inputs/Outputs**: Files that exist before and after the fix
- **Acceptance Criteria**: The specific condition that resolves the finding — derived from the Architect's recommendation
- **Verification Steps**: How to confirm the fix (e.g., "run `npm audit` and confirm no high/critical vulnerabilities", "run `cargo clippy` with no warnings")
- **Implementation Guidance**: Concrete steps to resolve the finding, based on the Inspector's evidence and the Architect's recommendation
- **Files Affected**: List files identified in the Inspector's evidence
- Mark sections with no relevant content as "N/A" (e.g., Edge Cases for straightforward dependency updates).

Keep legs atomic — one finding, one fix. If a finding requires touching many files but is conceptually one change (e.g., "replace all `any` casts"), that's still one leg.

#### 7d. Update Report Backlink

After scaffolding, update the "Maintenance Mission" section at the bottom of the maintenance report (from Phase 6) with a link to the newly created mission.

## Guidelines

### Read-Only Inspection

This skill NEVER modifies source files, configuration, or dependencies in the target project. The Inspector runs checks and reports findings. The only files created are the maintenance report and optionally a full maintenance mission scaffold (mission, flights, and legs) — all are Flight Control artifacts.

### Known Debt Awareness

Cross-reference Inspector findings against known debt from debriefs. Findings that match acknowledged debt should note "previously identified in {debrief}" rather than presenting them as new discoveries. This prevents alarm fatigue.

### Proportional Response

Not every codebase needs a maintenance mission. If the inspection finds only Advisory items, the report should clearly state "Flight Ready" and not push for unnecessary work.

### Honest Assessment

Report what you find, even if the codebase is in great shape. A clean report is valuable — it confirms the team's work quality and builds confidence for the next mission.

### Severity Calibration

- **Critical** is reserved for issues that would cause failures, security vulnerabilities, or data loss
- **Action Required** means the issue will compound or cause problems if left for another cycle
- **Advisory** is for genuine improvements that have no urgency
- **Pass** means the category was inspected and is healthy

## Output

Create the maintenance report artifact using the location and format defined in `.flightops/ARTIFACTS.md`.

After generating the report, summarize:
1. Overall assessment (Flight Ready or Maintenance Required)
2. Count of findings by severity
3. Top recommendations
4. Whether a maintenance mission was scaffolded (and if so, how many flights and legs)
