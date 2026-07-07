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

## Adding Future Migrations

To add a new migration:

1. Assign the next sequential ID (e.g., `006`)
2. Add its detection to `check-drift.sh` — emit `migration-pending:{id}` when the migration is needed, and nothing once it's been applied (idempotent)
3. Document it here: rationale, the **Actions** to perform (prefer `mv` over copy-and-delete to preserve file contents and git history), and a short **User message**
4. Note ordering if it depends on an earlier migration having run
5. Keep migrations non-destructive: rename and update references, never delete user content
