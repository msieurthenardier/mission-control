# Init-Project Migrations

When `/mission-control:init-project` runs, it upgrades projects from earlier versions of Flight Control. Detection is not done here — `check-drift.sh` is the single source of migration detection; it emits a `migration-pending:{id}` line for each migration that applies. This file describes, per id, *why* the migration exists, the *actions* to apply, and the *user message* to show. Migrations are idempotent: once applied, the corresponding `migration-pending:{id}` no longer fires.

## Migration Registry

### 001 — Rename `.flight-ops/` to `.flightops/`

Early versions of Flight Control used `.flight-ops/` (with a hyphen). The current convention is `.flightops/` (no hyphen).

**Detected by** `check-drift.sh` → `migration-pending:001`.

**Actions:**

1. Rename the directory:
   ```bash
   mv ".flight-ops" ".flightops"
   ```
2. Update `.gitignore` if it references the old name:
   ```bash
   sed -i 's/\.flight-ops/\.flightops/g' ".gitignore"
   ```

**User message:**
> Renaming `.flight-ops/` → `.flightops/` (updated naming convention)

---

### 002 — Rename `phases/` to `agent-crews/`

Early versions stored crew definitions in `.flightops/phases/`. The current convention is `.flightops/agent-crews/`.

**Detected by** `check-drift.sh` → `migration-pending:002`. Apply after 001 (operates on the post-rename `.flightops/` path).

**Actions:**

1. Rename the subdirectory:
   ```bash
   mv ".flightops/phases" ".flightops/agent-crews"
   ```

**User message:**
> Renaming `phases/` → `agent-crews/` (updated naming convention)

---

### 003 — Update lifecycle states to unified model

Flight Control now uses a unified lifecycle for both flights and legs: `planning → ready → in-flight → landed → completed` (or `aborted`). This replaces the old divergent states:

- **Flights**: `diverted` → `aborted`; added `completed` after `landed`
- **Legs**: `queued` → `planning`; `review` → `landed`; `blocked` → `aborted`; added `ready` and `completed`

**Detected by** `check-drift.sh` → `migration-pending:003`. Apply after 001–002.

**Actions:**

1. Update state definitions in ARTIFACTS.md:
   - Replace flight status line: `planning | ready | in-flight | landed | diverted` → `planning | ready | in-flight | landed | completed | aborted`
   - Replace leg status line: `queued | in-flight | review | completed | blocked` → `planning | ready | in-flight | landed | completed | aborted`
   - If a legacy `State Tracking` table is present, replace flight state tracking: `planning → ready → in-flight → landed (or diverted)` → `planning → ready → in-flight → landed → completed (or aborted)`
   - If a legacy `State Tracking` table is present, replace leg state tracking: `queued → in-flight → review → completed (or blocked)` → `planning → ready → in-flight → landed → completed (or aborted)`
   - Replace `landed | diverted` → `landed | aborted` in debrief templates
   - Replace `landed/diverted` → `landed/aborted` in debrief templates
   - Replace `completed | in-flight | blocked` → `completed | landed | in-flight | aborted` in flight log templates

2. Update existing artifact files in the project (if any):
   - In flight artifacts: replace `**Status**: diverted` → `**Status**: aborted`
   - In leg artifacts: replace `**Status**: queued` → `**Status**: planning`, `**Status**: review` → `**Status**: landed`, `**Status**: blocked` → `**Status**: aborted`
   - In flight log entries: replace `**Status**: blocked` → `**Status**: aborted`

   Find artifacts using the locations defined in ARTIFACTS.md (typically the `missions/` directory for file-based projects).

**User message:**
> Updating lifecycle states to unified model: flights and legs now share `planning → ready → in-flight → landed → completed (or aborted)`

---

### 004 — Install behavior-test artifacts and crew

Behavior tests are a new acceptance-test paradigm (AI-driven, multi-step, Witnessed pattern) shipped via the `/mission-control:behavior-test` skill. Each project needs the spec/run-log format added to its `ARTIFACTS.md` and the Executor + Validator crew prompts installed at `.flightops/agent-crews/behavior-tests-execution.md` so the run skill can drive its agents through the project.

**Detected by** `check-drift.sh` → `migration-pending:004`. Apply after 001–003.

**Actions:**

1. Install the crew file (Executor + Validator role definitions + prompts):
   ```bash
   cp "${SKILL_DIR}/defaults/agent-crews/behavior-tests-execution.md" \
      ".flightops/agent-crews/behavior-tests-execution.md"
   ```
   If the destination already exists (operator may have a customized copy from a prior partial install), prompt: overwrite, skip, or diff-and-merge.

2. Append the behavior-test artifact sections to the project's `ARTIFACTS.md`:
   - Add the "Behavior Test — Spec" section + format example.
   - Add the "Behavior Test — Run Log" section + format example.
   - Add `tests/behavior/{slug}.md` line to the Directory Structure tree.
   - If the project's ARTIFACTS.md still uses a legacy `State Tracking` table (pre-encoding-only layout), add two rows for the behavior-test spec/run states. Newer layouts carry those states inline in the format blocks, so no table edit is needed.
   - Reference: the canonical sections live in `${SKILL_DIR}/templates/ARTIFACTS-files.md`.

   If the operator has heavily modified ARTIFACTS.md (e.g., uses a non-filesystem artifact backend), surface the proposed insertions and ask before writing. Defer to operator on placement.

**User message:**
> Installing behavior-test artifact sections (spec + run-log format) in ARTIFACTS.md and the run-time crew (Executor + Validator) at `.flightops/agent-crews/behavior-tests-execution.md`. These let `/mission-control:behavior-test {slug}` run behavior tests against this project. Existing artifacts unaffected.

---

### 005 — Install Git Conventions section

Branch and commit naming used to be hardcoded in the `/mission-control:agentic-workflow` skill. It now defers to a `Git Conventions` section in the project's `ARTIFACTS.md` (branch/commit naming is a project convention, not protocol). Projects initialized before this change lack the section, leaving the Flight Director with no branch-naming source.

**Detected by** `check-drift.sh` → `migration-pending:005`. Apply after 001–004.

**Actions:**

1. Append a `Git Conventions` section to the project's `ARTIFACTS.md`, using the Flight Control defaults as the starting point:

   ```markdown
   ## Git Conventions

   How flight work is named in version control. Skills read these — adjust them to match your VCS conventions.

   - **Flight branch**: `flight/{number}-{slug}` — created at flight start (`git checkout -b flight/{number}-{slug}`)
   - **Commit subject**: `flight/{number}: {description}`, with a `Mission: {mission-number}` trailer
   ```

   - Reference: the canonical section lives in `${SKILL_DIR}/templates/ARTIFACTS-files.md`.
   - If the operator has heavily modified ARTIFACTS.md, surface the proposed insertion and ask before writing. Defer to operator on placement.

**User message:**
> Adding a `Git Conventions` section (branch + commit naming) to ARTIFACTS.md. `/mission-control:agentic-workflow` now reads branch/commit naming from here instead of hardcoding it, so you can match your VCS conventions. Existing artifacts unaffected.

---

### 006 — Install Squawk artifact and conventions

Flight Control's smallest planning unit used to be a mission, so small defects and routine servicing items either ran off-methodology or got inflated into a maintenance mission. The **squawk** — a standalone artifact beside the mission → flight → leg hierarchy, driven by the `/mission-control:squawk` skill — fills that gap. Projects initialized before this change have nowhere to store one.

No crew file is needed: squawks reuse the existing `leg-execution.md` crew (Developer + Reviewer).

**Detected by** `check-drift.sh` → `migration-pending:006`. Apply after 001–005.

**Actions:**

1. Append a `Squawk` artifact section to the project's `ARTIFACTS.md`, alongside the other core artifacts (mission, flight, leg). It defines the location `squawks/{id}-{slug}.md`, the status set `open | in-progress | completed | deferred | escalated`, and the report/evidence/corrective-action/verification/sign-off/disposition format.

2. Add a squawk id convention to the naming conventions section:

   ```markdown
   - **Squawk ids**: Monotonically increasing integers, project-wide, zero-padded to a minimum of four digits and widening past that as needed (`0001`, `0002`, … `9999`, `10000`, …). Unbounded by design — a long-lived project will pass any fixed width. Never reused, even after a squawk is completed or escalated.
   ```

3. Add squawk branch and commit naming to the existing `Git Conventions` section (added by migration 005):

   ```markdown
   - **Squawk branch**: `squawk/{id}-{slug}` for a single squawk; `squawk/turnaround-{YYYY-MM-DD}` when completing a batch of two or more
   - **Squawk commit subject**: `squawk/{id}: {description}` for a single squawk; `squawk: turnaround {YYYY-MM-DD}` for a batch, with a `Squawks: {id}, {id}` trailer listing every id completed
   ```

4. Add `squawks/{id}-{squawk-slug}.md` to the Directory Structure tree.

   - Reference: the canonical sections live in `${SKILL_DIR}/templates/ARTIFACTS-files.md`.
   - If the operator has heavily modified ARTIFACTS.md (e.g. a non-filesystem artifact backend), surface the proposed insertions and ask before writing. Defer to the operator on placement and on how squawk ids map onto their backend.

**User message:**
> Adding a `Squawk` artifact section to ARTIFACTS.md, plus squawk id and branch/commit conventions. Squawks are standalone small fixes — one defect or one routine update, no mission required — logged and completed via `/mission-control:squawk`. They reuse your existing `leg-execution` crew, so no new crew file. Existing artifacts unaffected.

---

### 007 — Refresh CLAUDE.md for the mission-control plugin

Flight Control used to run from a separate mission-control checkout that held a registry of projects; the project's `CLAUDE.md` only pointed at `.flightops/`. It now ships as the `mission-control` Claude Code plugin and runs from the project itself, with skills invoked as `/mission-control:<skill>`. The Flight Director instructions that lived in mission-control's own `CLAUDE.md` (invoke `agentic-workflow` when a leg is ready, planning skills never touch source, spawned agents have no Skill tool, drift notices are recommend-only) now belong in the project's `CLAUDE.md`. Projects initialized before this change have a Flight Operations section without them.

**Detected by** `check-drift.sh` → `migration-pending:007`. Apply after 001–006.

**Actions:**

1. In the project's `CLAUDE.md`, replace the contents of the existing Flight Operations section with the current snippet from init-project's Step 7. Preserve anything the project added to that section that is not in the old default (extra reading order entries, project-specific notes) by carrying it below the snippet.

2. Crew files under `.flightops/agent-crews/` from before this change describe `{project-slug}` as coming from `projects.md` and give spawned agents a `{target-project}/` context. Both are informational — the slug is now the repository directory name (or the name from the git remote), and agents inherit the project root as their working directory. Offer to refresh them via init-project Step 6's review-against-defaults path; do not rewrite customized crew files silently.

**User message:**
> Refreshing the Flight Operations section of CLAUDE.md for the mission-control plugin: skills are now `/mission-control:<skill>` and run from this project, and the Flight Director instructions move here. Optionally refresh crew files to the latest defaults. Existing artifacts unaffected.

---

### 008 — Move the leg-execution crew to the flight-end review and commit

`/mission-control:agentic-workflow` used to review and commit after every leg: the Developer signalled `[HANDOFF:review-needed]`, a Reviewer checked that leg, and a commit agent signalled `[COMPLETE:leg]`. It now batches: legs land uncommitted, the Developer signals `[LAND:leg]`, and one review and one commit happen after the last autonomous leg. The skill loads its Developer and Reviewer prompts from the project's `.flightops/agent-crews/leg-execution.md`, so a project initialized before this change spawns agents that follow the old protocol while the Flight Director expects the new one — the Developer commits a leg it was told to leave uncommitted, and never emits the signal the Flight Director waits for.

Signals and the review/commit cadence are methodology, not project customization (the crew file's own note says so), which is why this crew-content change is a migration rather than the usual informational drift.

**Detected by** `check-drift.sh` → `migration-pending:008`. Apply after 001–007. Apply between flights: a flight already in progress under the old cadence should land first.

**Actions:**

1. Show the diff between the project's `leg-execution.md` and the current default at `${SKILL_DIR}/defaults/agent-crews/leg-execution.md` (init-project Step 6's review path). If the project's file is the old default unchanged, or the operator prefers it, overwrite with the current default and stop here.

2. Otherwise apply these edits to the project's file, preserving any project customization around them:
   - **Signals note**: `[COMPLETE:leg]` → `[LAND:leg]`.
   - **Interaction Protocol — Implementation**: the Developer marks the leg `landed`, updates the flight log, and signals `[LAND:leg]`; the Flight Director proceeds to the next leg. Drop any "signals `[HANDOFF:review-needed]`" step.
   - **Interaction Protocol — Code Review and Commit**: mark both once per flight. Review runs after the last autonomous leg lands over every leg's changes; the commit agent commits code + artifacts in one commit and reports the commit ref.
   - **Template Variables**: `{leg-number}` is available in `review-leg-design` and `implement` only.
   - **Implement prompt**: end with "update leg status to landed and report what you implemented and how you verified it. Do not commit. Signal [LAND:leg]." — replacing any "Do NOT commit yet — signal [HANDOFF:review-needed]" ending.
   - **Review, Review Accessibility, Fix Review Issues prompts**: `phase: flight-review`; remove the `leg: {leg-number}` line; review "all changes on the flight branch relative to its base" rather than "since the last commit".
   - **Commit prompt**: `phase: flight-commit`; remove the `leg:` line; reduce the body to the mechanical commit — commit all uncommitted changes (code + artifacts) in a single commit per the Git Conventions in `.flightops/ARTIFACTS.md`, including the artifact updates the Flight Director listed at spawn, then report the commit ref. Remove the per-leg checklist (acceptance criteria, leg status, flight.md, mission.md) and any `[COMPLETE:leg]` signal; those steps are protocol and now live in `FLIGHT_OPERATIONS.md`.

3. Re-run `check-drift.sh`; `migration-pending:008` must no longer fire.

**User message:**
> Updating `.flightops/agent-crews/leg-execution.md` for the flight-end review and commit: legs now land uncommitted and signal `[LAND:leg]`; one review and one commit happen after the last leg. Your customizations are kept; only the protocol steps and prompts change. Existing artifacts unaffected.

---

### 009 — Install the Service Report artifact section

`/mission-control:service-report` sweeps a project's accumulated flight and mission debriefs for recurring methodology trends and sends them upstream to the mission-control repository as GitHub issues. It is operator-invoked on no cadence, typically after several missions. It needs somewhere to record what was sent and the evidence behind it — which the next sweep reads to avoid re-reporting — and a project-level switch for operators who cannot post to public repositories at all. Projects initialized before this change have neither, so the skill has no audit trail to write and no way to know the project has opted out.

**Detected by** `check-drift.sh` → `migration-pending:009`. Apply after 001–008.

**Actions:**

1. Append a `Service Report` artifact section to the project's `ARTIFACTS.md`, alongside the `Squawk` section. The canonical section lives in `${SKILL_DIR}/templates/ARTIFACTS-files.md` — location, the `**Upstream reporting**: enabled` switch, and the format block.

2. Add `service-reports/{id}-{report-slug}.md` to the Directory Structure tree, and a service report id line to Naming Conventions (same scheme as squawk ids, separate sequence).

3. Ask the operator whether upstream reporting should be `enabled` or `disabled` for this project, and write their answer into the new section. The template ships `unset` and the skill fails closed on it, so an unanswered switch opts the project out. Do not assume — ask. Per-report approval of the exact text applies regardless; this switch decides whether the channel exists at all.

4. Update the **Mission Debrief** artifact's methodology-feedback guidance in `ARTIFACTS.md`. Projects initialized before this change ask only for `{Improvements to Flight Control process itself}`; the current template asks for what each finding cost, how many flights it recurred in, and where it went (local fix, local lesson, or methodology observation). `/mission-control:mission-debrief` Phase 7 depends on that shape, and a later service report sweep can only find trends in observations that were recorded this way.

   Write this idempotently — check whether the guidance already asks for cost and recurrence before replacing it. Detection for this migration keys on the `Service Report` heading only, so this action gets no second chance to fire.

5. Add a **methodology observations** block to the Flight Debrief artifact format in `ARTIFACTS.md`, and a plugin version field to both the Flight Debrief and Mission Debrief formats. Flight debriefs are the sweep's primary corpus, and without a place to record them, `/mission-control:flight-debrief` Phase 4's output has no destination. The version is what lets a later sweep tell whether a difficulty survived a plugin release; it cannot be reconstructed after the fact.

   Per the skill–project boundary, suggest the heading rather than prescribing it — the project owns this file. Also idempotent, and covered by the same one-shot detection caveat as action 4.

   Existing debriefs stay as they are. A sweep reading a corpus written before this migration reports `unrecorded before {version}` rather than inventing a version span.

If the operator has heavily modified `ARTIFACTS.md` (e.g. a non-filesystem artifact backend), surface the proposed insertion and ask before writing. Defer to the operator on placement.

No crew file ships with this migration. The Redaction Reviewer is spawned with instructions issued directly from the skill, deliberately — it is a disclosure control, and a project-modifiable file is the wrong place to keep one.

**User message:**
> Adding a `Service Report` artifact section to ARTIFACTS.md, a project-level upstream reporting switch, a methodology observations block in the Flight Debrief format, and a plugin version field on both debrief formats. Service reports send recurring Flight Control **methodology** trends upstream as GitHub issues, found by sweeping your accumulated debriefs whenever you choose to run `/mission-control:service-report` — never anything about this project, and never without you approving the exact text first. Set the switch to `disabled` if this project must not post to public repositories. Existing artifacts unaffected.

---

### 010 — Name the interactive session as the Flight Director

The Flight Operations snippet installed by 007 told the Flight Director what to do when a leg is ready, but never said which session *is* the Flight Director. A session could read it as a role it switches into for execution, rather than the role it holds throughout. The current snippet states it outright: the session the human talks to is the Flight Director, and spawned agents are crew.

**Detected by** `check-drift.sh` → `migration-pending:010`. Apply after 001–009. Never pending alongside 007, which installs the current snippet itself.

**Actions:**

1. In the project's `CLAUDE.md` Flight Operations section, replace the **Flight Director role** paragraph with the one in init-project's Step 7 snippet. Leave the rest of the section, including anything the project added, as it is. If the project has rewritten that paragraph, show the new opening sentences and ask where they belong.

**User message:**
> Updating the Flight Director paragraph in CLAUDE.md's Flight Operations section: it now states that this session is the Flight Director and spawned agents are crew. Nothing else in the section changes. Existing artifacts unaffected.

---

## Adding Future Migrations

To add a new migration:

1. Assign the next sequential ID (e.g., `011`)
2. Add its detection to `check-drift.sh` — emit `migration-pending:{id}` when the migration is needed, and nothing once it's been applied (idempotent)
3. Document it here: rationale, the **Actions** to perform (prefer `mv` over copy-and-delete to preserve file contents and git history), and a short **User message**
4. Note ordering if it depends on an earlier migration having run
5. Keep migrations non-destructive: rename and update references, never delete user content
