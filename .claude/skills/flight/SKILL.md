---
name: flight
description: Create technical flight specifications from missions. Use when breaking down a mission into implementable work or planning technical approach.
---

# Flight Specification

Create a technical flight spec from a mission.

## Prerequisites

- Project must be initialized with `/init-project` (`.flightops/ARTIFACTS.md` must exist)
- A mission must exist before creating a flight

## Workflow

### Phase 1: Context Gathering

1. **Identify the target project**
   - Read `projects.md` to find the project's path

2. **Verify project is initialized**
   - Check if `{target-project}/.flightops/ARTIFACTS.md` exists
   - **If missing**: STOP and tell the user to run `/init-project` first
   - Do not proceed without the artifact configuration

3. **Read the artifact configuration**
   - Read `{target-project}/.flightops/ARTIFACTS.md` for how this project handles each artifact — its storage location, format, and any actions the project defines at create and transition time (e.g., transitioning a ticket, posting a notification)

4. **Read the parent mission**
   - Understand the outcome being pursued
   - Identify which success criteria this flight addresses
   - Note constraints that apply

5. **Check existing flights**
   - What flights already exist for this mission?
   - What's been completed vs. in progress?
   - Are there dependencies on other flights?

6. **Review recent flight debriefs for relevant observations**
   - Read recent flight debriefs in the project (within and adjacent to this mission)
   - Look for test metrics observations: known slow suites, recurring flakes, persistent failures, growing skip lists — anything narrated by prior debriefs
   - Look for unresolved technical concerns or recommendations that touch this flight's likely scope
   - Carry forward into the technical approach and risk picture: e.g. "this area has slow integration tests, account for that in time estimates"; "known flake in suite X, plan to fix or quarantine if touching that area"; "prior debrief flagged Y — verify whether still relevant"

### Phase 1b: Upstream Reconnaissance

**Applies when**: The flight sources work items from a prior artifact that cites specific code locations — a maintenance report, a flight or mission debrief that enumerates outstanding follow-ups, an issue tracker, or a security audit. Skip this phase for greenfield flights where no source artifact pre-enumerates findings.

Source artifacts go stale. Items cited weeks or even days ago may have been incidentally fixed by intervening flights, partially addressed, or the cited file/line may have moved. Without a recon pass, stale items get drafted into legs and only get caught at design review or implementation — wasted artifact churn and rework.

**Goal**: Before designing legs, walk every cited item against current code and classify it.

1. **Enumerate source items**
   - Read the source artifact in full and identify every item it treats as outstanding, actionable work — regardless of how the artifact organizes them. Different projects use different headings, severity labels, and status conventions; identify items by intent, not by literal section name.
   - Capture each item's cited file paths, line numbers, and the change it describes

2. **Verify each item against current code**
   - Read the cited locations (or grep for the cited symbols if line numbers have drifted)
   - Determine whether the described gap still exists

3. **Classify each item** into one of:
   - **`confirmed-live`** — gap still exists, item is real work
   - **`already-satisfied`** — code now reflects what the item asked for; recommend retiring
   - **`partially-satisfied`** — some sub-points done, others not; scope down
   - **`needs-human-recheck`** — cannot be verified mechanically (runtime state, external system, credentials, infrastructure that isn't in the repo)
   - **`drifted`** — cited location moved or symbol renamed; needs re-locating before classification

4. **Produce a Reconnaissance Report**
   - Append the report to the flight log under a clearly-titled section (something like `## Reconnaissance Report` if the project's flight-log conventions don't dictate otherwise)
   - One row per source item: `{item-id} | {classification} | {evidence: file:line or "cannot verify from repo"} | {recommendation}`
   - For `already-satisfied`: cite the specific code that satisfies the item, so the user can audit your call

5. **Default to flag-for-human, not auto-retire**
   - Do NOT silently drop items classified as `already-satisfied` or `partially-satisfied`
   - Present the recon report to the user before proceeding to Phase 2 and ask: "Confirm retirements / accept partial scope / override any classifications?"
   - The user has authority to keep an item live even if you think it's satisfied (e.g., the satisfying code is incomplete in ways you can't see)

6. **Carry retired items into the flight artifact**
   - In the section of the flight artifact the project uses to enumerate scope items contributing to mission criteria, retired items appear as completed `[x]` entries with the satisfying evidence inline — they are NOT silently dropped from the spec
   - This preserves traceability: a future reader can see all source items were considered, and which ones were judged already-satisfied during reconnaissance

### Phase 2: Code Interrogation

Explore the target project's codebase to inform the technical approach:

1. **Identify relevant code areas**
   - What existing code relates to this flight?
   - What patterns are already established?
   - What dependencies exist?

2. **Find files likely to be affected**
   - Source files to modify
   - Test files to create/update
   - Configuration changes needed

3. **Understand existing patterns**
   - Code style and conventions
   - Error handling approaches
   - Testing patterns

4. **Check for schema/migration implications**
   - Does this flight add or modify database tables?
   - What migration tooling does the project use?
   - Are there existing migration patterns to follow?

### Phase 3: User Input

Before asking structured technical questions, share a brief summary of what you learned during context gathering and code interrogation, then prompt the user for open-ended input:

- "Here's what I've gathered about the mission context and codebase: [summary]. Before I ask specific technical questions, what are your thoughts on what this flight should cover? Feel free to share approach preferences, priorities, concerns — anything that should shape this flight."

Use the user's response to inform and focus the crew interview questions that follow.

### Phase 4: Crew Interview

Ask technical questions to resolve the approach:

1. **Technical approach**
   - "Should we extend existing code or create new modules?"
   - "What's the preferred pattern for [specific decision]?"
   - "Are there performance considerations?"

2. **Open questions**
   - Surface ambiguities in requirements
   - Clarify edge cases
   - Identify unknowns

3. **Design decisions**
   - Document choices and rationale
   - Get agreement on trade-offs
   - Note constraints discovered
   - For any criterion verified against the real environment, the behavior test's **apparatus** (which measurement surface drives and observes it) is itself a design decision — vet it like any other
   - A DD that rests on an empirical premise should have that premise verified before it's locked
   - **Premise-audit the apparatus on BOTH axes — can it *act*, and can it *observe*?** It's easy to audit only the feasibility/ingestion premise ("can the apparatus drive the system the way a real actor would?") and forget the **assertion/observability premise** ("can the apparatus *observe*, through an existing surface, everything the acceptance criteria must assert?"). Both are static facts checkable at planning with code citations. A skipped observability audit surfaces later as a mid-flight scramble for a way to read the state under test — e.g. a verification harness that can drive real traffic but then can't locate or read the record that traffic produced, forcing a test-only seam to be added reactively. Cite the read path (the endpoint/projection/log the assertion will consume) alongside the act path when locking the apparatus DD.

4. **Prerequisites verification**
   - "Is [dependency] ready?"
   - "Do we have access to [resource]?"

5. **Validation approach**
   - "How will this flight be validated?"
   - "Is test automation needed, or is manual verification sufficient?"
   - "What tests should be created or updated?"

### Phase 5: Spec Creation

Persist the flight artifact following the conventions `.flightops/ARTIFACTS.md` defines for it, then perform any create-time handling it defines for that artifact (e.g., opening a ticket, posting a notification; default: none).

Also create the flight log artifact (empty, ready for execution notes), likewise per its ARTIFACTS.md conventions.

**Verification approach — consider behavior tests.** If the flight's acceptance criteria need real-environment observation that unit/integration tests can't cover (UI flows, multi-component interactions, AI agent behavior), author one or more **behavior test** specs inline as part of this phase — draft them now, before legs are locked, so the apparatus choice and key observable shape the leg breakdown rather than being retrofitted. At minimum a draft fixes the key observable and a rough step count; the apparatus choice is a Design Decision (see Phase 4). A behavior test is a Zephyr-style Action | Expected Result table run via `/behavior-test {slug}` with two live agents (Executor + Validator) using the Witnessed pattern. Write the spec to the configured behavior-test directory (per ARTIFACTS.md; default `tests/behavior/{slug}.md`); reference the slug in the flight's Verification section. See `.claude/skills/behavior-test/AUTHORING.md` for the authoring guide (when to use, interview shape, spec format, common pitfalls). Don't author them speculatively — only when the verification cost is justified by the value of real-environment observation.

### Phase 5b: Design Review

Spawn an Architect agent to validate the flight spec against the real codebase before presenting it to the crew.

Read `{target-project}/.flightops/agent-crews/flight-design.md` for crew definitions and prompts (fall back to defaults at `.claude/skills/init-project/defaults/agent-crews/flight-design.md`).

**Validate structure**: The phase file MUST contain `## Crew`, `## Interaction Protocol`, and `## Prompts` sections with fenced code blocks. If the file exists but is malformed, STOP and tell the user: "Phase file `flight-design.md` is missing required sections. Either fix it manually or re-run `/init-project` to reset to defaults."

1. **Spawn an Architect agent** in the target project context (Task tool, `subagent_type: "general-purpose"`)
   - Provide the "Review Flight Design" prompt from the flight-design phase file's Prompts section
   - The Architect reads the flight spec and cross-references design decisions, prerequisites, technical approach, and leg breakdown against actual codebase state and architecture best practices
   - The Architect provides a structured assessment: approve, approve with changes, or needs rework
2. **Incorporate feedback** — update the flight artifact to address issues raised
   - High-severity issues: must fix before proceeding
   - Medium-severity issues: fix unless there's a clear reason not to
   - Low-severity issues and suggestions: apply at discretion
3. **Re-review if substantive changes were made** — spawn another Architect for a second pass
   - Skip if only minor/cosmetic fixes were applied
   - **Max 2 design review cycles** — if issues persist after 2 rounds, escalate to human
4. **Proceed to Phase 6** with a codebase-validated spec

### Phase 6: Iterate

1. Walk through the spec with the crew
2. Validate technical approach is sound
3. Confirm leg breakdown is appropriate
4. Refine until approved

## Guidelines

### Flight Sizing

A well-sized flight:
- Takes 1-3 days of focused work
- Breaks into 1-4 legs typically — each a coherent feature slice; often 1-2 plus an optional HAT leg
- Has a clear, verifiable objective
- Addresses specific mission criteria

**Too small**: No flight-level design decisions to resolve — a single obvious change
**Too large**: More than a week of work, vague checkpoints

### Leg Identification

Break flights into legs based on decision and risk boundaries, not effort:
- Each leg is a coherent feature slice — atomic (independently completable), with clear inputs and outputs, carrying its own tests and doc updates
- Default to few, large legs; add a boundary only where a mid-flight human decision or a risky, hard-to-reverse step (schema migration, interface break) needs its own checkpoint
- Do NOT split by task type — model, endpoint, validation, and tests belong in one leg; an implementing agent carries the full slice in one pass
- Consider dependencies between legs

**For scaffolding flights**: Include a final `verify-integration` leg

**For interface changes**: Identify consumers that need updates

**For documentation**: Consider whether README, CLAUDE.md, or other docs need updates as part of this flight — especially for flights adding new CLI commands, API endpoints, or configuration options

**For carry-forward debt from prior debriefs**: when multiple small items touch the same files or directories, bundle them into a single shared-surface leg rather than scheduling separate flights or letting them decay. Items that don't share a surface stay separate — bundling unrelated work just to "pull forward" is how scope creep enters maintenance work.

**For schema changes**: Include explicit migration legs and verify against the live database, not just mocks

**For HAT and alignment**: During the crew interview, ask the user whether they'd like to include an interactive HAT (human acceptance test) and alignment leg. Explain that this optional leg is a guided HAT session — the agent walks the user through a series of tests and verification steps, fixing issues along the way until the user is satisfied with the results. If the user opts in, include it in the breakdown, marked as optional.

### Pre-Flight Rigor

- Open questions MUST be resolved before execution
- Design decisions MUST be documented with rationale
- Prerequisites MUST be verified, not assumed
- **Environment conflicts**: Flights introducing network services (ports, databases, containers) must check for conflicts with existing services on the developer's machine during planning. Ask: "What else is running that could conflict?"
- **Behavior-test execution prerequisites**: When a flight names a behavior test as an acceptance gate, record as a prerequisite — verified at planning — the apparatus-audited environment (running instance, live browser/MCP, fixtures). Probe the apparatus before the flight lands. The Executor + Validator run re-spawn-per-checkpoint by default; live continuation (experimental `SendMessage`, requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) is an optimization, not a prerequisite.

### Adaptive Planning

- Flights can be modified during `planning` state
- Once `in-flight`, flights may still be modified (e.g., changing planned legs) as long as the flight log captures the change and rationale
- New legs can be added if scope grows

## Output

Persist the following artifacts per the conventions `.flightops/ARTIFACTS.md` defines for each:

1. **Flight spec** — The flight plan
2. **Flight log** — Empty, ready for execution notes
