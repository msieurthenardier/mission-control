---
name: preflight-check
description: Verify the current project has current Flight Control methodology files, crew definitions, and migrations for the installed mission-control plugin version. Reports a full drift diagnosis and offers to run init-project to remediate. Run after updating the plugin.
---

# Preflight Check

Verify the current project's `.flightops/` is current with the installed mission-control plugin. Reports findings and offers to run `/mission-control:init-project` to remediate.

The SessionStart hook surfaces drift in one line; this skill is the full diagnosis. It never changes anything itself.

## When to Use

- After updating the mission-control plugin, in each project you work on
- When the SessionStart drift notice appears and you want the details before remediating
- When onboarding to a project whose setup may be stale

## Conventions

- The **project** is the current working directory.
- `${SKILL_DIR}` is the directory this SKILL.md was loaded from inside the installed plugin.

## Workflow

### Phase 1: Check the Project

1. **Confirm the current working directory is a project root.** If it is not, STOP and ask the user to run the skill from the project's root.
2. **Run the drift detector**:
   ```bash
   bash "${SKILL_DIR}/../init-project/check-drift.sh" \
     "${SKILL_DIR}/../init-project" \
     ".flightops"
   ```
3. **Parse the output** and classify each line:

| Status | Meaning | Action Needed |
|--------|---------|---------------|
| `missing` | No `.flightops/` directory | Needs `/mission-control:init-project` |
| `outdated` | Methodology files differ from the installed plugin | Needs `/mission-control:init-project` |
| `current` | Methodology files match | None for methodology |
| `agent-crews:missing` | No crew directory at all | Needs `/mission-control:init-project` |
| `agent-crews:empty` | Crew directory exists but empty | Needs `/mission-control:init-project` |
| `crew-missing:{file}` | Specific crew file missing (new skill) | Needs crew file added |
| `migration-pending:{id}` | A methodology migration applies (legacy layout, outdated states, missing sections) | Needs migration via `/mission-control:init-project` |

### Phase 2: Report

Present a summary:

> **Preflight Status**
>
> | Check | Status | Detail |
> |-------|--------|--------|
> | Methodology files | outdated | `FLIGHT_OPERATIONS.md` differs from installed plugin |
> | Crew files | 1 missing | `behavior-tests-execution.md` not found |
> | Migrations | 2 pending | 005 (Git Conventions), 006 (Squawks) |
>
> **This project needs attention.** / **This project is current.**

For each pending migration, include its one-line user message from `${SKILL_DIR}/../init-project/migrations.md` so the user knows what remediation will change.

### Phase 3: Remediate

If anything needs attention:

> "Want me to run `/mission-control:init-project` now to bring this project current?"

On yes, run the init-project workflow (read `${SKILL_DIR}/../init-project/SKILL.md` and execute it):
- If only crew files are missing: skip straight to its Step 6 (Configure Project Crew) — the re-run path copies missing crew files from defaults without touching existing ones
- If methodology files are outdated: run the full workflow
- If migrations are pending: run from its Step 2 (migrations)

On no, stop after the report.

## Guidelines

### Non-Destructive

This skill never overwrites customized files without user consent. The underlying `/mission-control:init-project` workflow:
- Copies missing crew files from defaults (safe — fills gaps)
- Asks before updating existing crew files (respects customization)
- Never overwrites `ARTIFACTS.md` (project-specific)

### Missing Crew Files vs. Drift

These are distinct situations:
- **Missing crew file**: A new default crew was added to the plugin but the project doesn't have it yet. This is a gap — the file should be copied from defaults.
- **Crew file drift**: A project's crew file differs from the current default. This is expected — projects customize their crews. Report it as informational but do not flag it as needing remediation.

### Quick and Quiet

If the project is current, say so in one line and stop. No confirmation prompts needed when there's nothing to do.
