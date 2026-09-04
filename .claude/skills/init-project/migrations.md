# Init-Project Migrations

When `/init-project` runs, it upgrades projects from earlier versions of Flight Control. Detection is not done here — `check-drift.sh` is the single source of migration detection; it emits a `migration-pending:{id}` line for each migration that applies. This file describes, per id, *why* the migration exists, the *actions* to apply, and the *user message* to show. Migrations are idempotent: once applied, the corresponding `migration-pending:{id}` no longer fires.

## Migration Registry

### 001 — Rename `.flight-ops/` to `.flightops/`

Early versions of Flight Control used `.flight-ops/` (with a hyphen). The current convention is `.flightops/` (no hyphen).

**Detected by** `check-drift.sh` → `migration-pending:001`.

**Actions:**

1. Rename the directory:
   ```bash
   mv "{target-project}/.flight-ops" "{target-project}/.flightops"
   ```
2. Update `.gitignore` if it references the old name:
   ```bash
   sed -i 's/\.flight-ops/\.flightops/g' "{target-project}/.gitignore"
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
   mv "{target-project}/.flightops/phases" "{target-project}/.flightops/agent-crews"
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

Behavior tests are a new acceptance-test paradigm (AI-driven, multi-step, Witnessed pattern) shipped via the `/behavior-test` skill on the mission-control side. Each target project needs the spec/run-log format added to its `ARTIFACTS.md` and the Executor + Validator crew prompts installed at `.flightops/agent-crews/behavior-tests-execution.md` so the run skill can drive its agents through the project.

**Detected by** `check-drift.sh` → `migration-pending:004`. Apply after 001–003.

**Actions:**

1. Install the crew file (Executor + Validator role definitions + prompts):
   ```bash
   cp ".claude/skills/init-project/defaults/agent-crews/behavior-tests-execution.md" \
      "{target-project}/.flightops/agent-crews/behavior-tests-execution.md"
   ```
   If the destination already exists (operator may have a customized copy from a prior partial install), prompt: overwrite, skip, or diff-and-merge.

2. Append the behavior-test artifact sections to the project's `ARTIFACTS.md`:
   - Add the "Behavior Test — Spec" section + format example.
   - Add the "Behavior Test — Run Log" section + format example.
   - Add `tests/behavior/{slug}.md` line to the Directory Structure tree.
   - If the project's ARTIFACTS.md still uses a legacy `State Tracking` table (pre-encoding-only layout), add two rows for the behavior-test spec/run states. Newer layouts carry those states inline in the format blocks, so no table edit is needed.
   - Reference: the canonical sections live in `.claude/skills/init-project/templates/ARTIFACTS-files.md`.

   If the operator has heavily modified ARTIFACTS.md (e.g., uses a non-filesystem artifact backend), surface the proposed insertions and ask before writing. Defer to operator on placement.

**User message:**
> Installing behavior-test artifact sections (spec + run-log format) in ARTIFACTS.md and the run-time crew (Executor + Validator) at `.flightops/agent-crews/behavior-tests-execution.md`. These let `/behavior-test {slug}` run behavior tests against this project. Existing artifacts unaffected.

---

### 005 — Install Git Conventions section

Branch and commit naming used to be hardcoded in the `/agentic-workflow` skill. It now defers to a `Git Conventions` section in the project's `ARTIFACTS.md` (branch/commit naming is a project convention, not protocol). Projects initialized before this change lack the section, leaving the Flight Director with no branch-naming source.

**Detected by** `check-drift.sh` → `migration-pending:005`. Apply after 001–004.

**Actions:**

1. Append a `Git Conventions` section to the project's `ARTIFACTS.md`, using the Flight Control defaults as the starting point:

   ```markdown
   ## Git Conventions

   How flight work is named in version control. Skills read these — adjust them to match your VCS conventions.

   - **Flight branch**: `flight/{number}-{slug}` — created at flight start (`git checkout -b flight/{number}-{slug}`)
   - **Commit subject**: `flight/{number}: {description}`, with a `Mission: {mission-number}` trailer
   ```

   - Reference: the canonical section lives in `.claude/skills/init-project/templates/ARTIFACTS-files.md`.
   - If the operator has heavily modified ARTIFACTS.md, surface the proposed insertion and ask before writing. Defer to operator on placement.

**User message:**
> Adding a `Git Conventions` section (branch + commit naming) to ARTIFACTS.md. `/agentic-workflow` now reads branch/commit naming from here instead of hardcoding it, so you can match your VCS conventions. Existing artifacts unaffected.

---

### 006 — Install Squawk artifact and conventions

Flight Control's smallest planning unit used to be a mission, so small defects and routine servicing items either ran off-methodology or got inflated into a maintenance mission. The **squawk** — a standalone artifact beside the mission → flight → leg hierarchy, driven by the `/squawk` skill — fills that gap. Projects initialized before this change have nowhere to store one.

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

   - Reference: the canonical sections live in `.claude/skills/init-project/templates/ARTIFACTS-files.md`.
   - If the operator has heavily modified ARTIFACTS.md (e.g. a non-filesystem artifact backend), surface the proposed insertions and ask before writing. Defer to the operator on placement and on how squawk ids map onto their backend.

**User message:**
> Adding a `Squawk` artifact section to ARTIFACTS.md, plus squawk id and branch/commit conventions. Squawks are standalone small fixes — one defect or one routine update, no mission required — logged and completed via `/squawk`. They reuse your existing `leg-execution` crew, so no new crew file. Existing artifacts unaffected.

---

## Adding Future Migrations

To add a new migration:

1. Assign the next sequential ID (e.g., `006`)
2. Add its detection to `check-drift.sh` — emit `migration-pending:{id}` when the migration is needed, and nothing once it's been applied (idempotent)
3. Document it here: rationale, the **Actions** to perform (prefer `mv` over copy-and-delete to preserve file contents and git history), and a short **User message**
4. Note ordering if it depends on an earlier migration having run
5. Keep migrations non-destructive: rename and update references, never delete user content
