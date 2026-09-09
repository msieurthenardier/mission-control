---
name: init-project
description: Initialize the current project for Flight Control. Creates .flightops directory with methodology reference, artifact configuration, and crew definitions, and applies pending methodology migrations. Run before using other Flight Control skills on a new project, and after updating the mission-control plugin.
---

# Project Initialization

Prepare the current project for Flight Control by creating the `.flightops/` directory with methodology references, artifact configuration, and crew definitions.

**This skill produces documentation only.** It creates and updates `.flightops/` and the project's `CLAUDE.md`; it never modifies source files.

## When to Use

Run `/mission-control:init-project` in the project's root directory when:
- Starting to use Flight Control on a new project
- The SessionStart drift notice or `/mission-control:preflight-check` reports the project is behind the installed plugin
- Another skill indicates the reference needs to be synced

## Conventions

- The **project** is the current working directory. All paths below are relative to its root.
- `${SKILL_DIR}` is the directory this SKILL.md was loaded from inside the installed plugin. It holds the synced files, templates, defaults, and `check-drift.sh`.

## Workflow

### 1. Confirm the Project Root

Confirm the current working directory is the root of a project (a git repository or an equivalent project root). If it is not, STOP and ask the user to run the skill from the project's root directory.

### 2. Detect Drift and Apply Migrations

Run the drift detector once — it reports synced-file status, crew status, and any pending migrations:

```bash
bash "${SKILL_DIR}/check-drift.sh" "${SKILL_DIR}" ".flightops"
```

Keep its full output; step 3 reuses the first line. To handle migrations:

1. **Collect `migration-pending:{id}` lines** from the output. If there are none, proceed silently to the next step.
2. **Read `${SKILL_DIR}/migrations.md`** for each reported id's rationale, actions, and user message.
3. **Present a summary** to the user:
   > "Detected an outdated layout in this project. The following migrations are available:"
   >
   > - _Each pending migration's user message_
   >
   > "Apply these migrations?"
4. **On confirmation**, apply each pending migration's actions in ascending id order (later migrations assume earlier ones have run).
5. **On decline**, warn the user that some skills may not work correctly until migrated, but continue with the existing layout.

### 3. Sync Status

The first line of the `check-drift.sh` output from step 2 is the synced-file status:
- `missing` - `.flightops/` doesn't exist in this project
- `outdated` - Directory exists but files differ from the installed plugin
- `current` - All files are up-to-date

### 4. Prompt and Sync Methodology Files

Based on the status:

**If `missing`**:
> "Flight operations directory not found. Create `.flightops/` with methodology references?"

**If `outdated`**:
> "Flight operations references in this project are outdated. Update?"

**If `current`**:
> "Flight operations references are up-to-date in this project."

If the user confirms, create/update the directory:

```bash
mkdir -p ".flightops"
cp "${SKILL_DIR}/FLIGHT_OPERATIONS.md" ".flightops/"
cp "${SKILL_DIR}/README.md" ".flightops/"
```

### 5. Configure Artifact System (New Projects Only)

**Only if ARTIFACTS.md doesn't exist**, copy the template:

```bash
cp "${SKILL_DIR}/templates/ARTIFACTS-files.md" ".flightops/ARTIFACTS.md"
```

**If ARTIFACTS.md already exists**, do not modify it — it's project-specific and may have been customized.

### 6. Configure Project Crew

Set up phase-specific crew definitions that control how the Flight Director interacts with project-side agents.

1. **Check if `.flightops/agent-crews/` exists**

   **If missing** (first run):
   - Copy all defaults from `${SKILL_DIR}/defaults/agent-crews/` to `.flightops/agent-crews/`
   - Brief the user:
     > "Default crew has been set up for all phases. Your agent crews define who the Flight Director works with during each phase — which agents exist, their roles, models, and prompts."
   - Ask about customization:
     > "Want to customize any agent crew? (Most projects work fine with defaults)"
   - If yes: ask which crew → show current definitions → walk through changes (add/remove/modify roles, adjust prompts, change interaction protocol)
   - If no: proceed with defaults

   **If exists** (re-run):
   - Copy any missing crew files from defaults (new crews added to the methodology)
   - Ask the user:
     > "Agent crew files already exist. Default crew definitions may have been updated since your project was initialized. Want to review and update any crew files to the latest defaults?"
   - If yes: for each file, show what changed between their version and the current default, ask whether to overwrite or keep their version
   - If no: leave all existing files untouched

### 7. Update CLAUDE.md

Check if the project's `CLAUDE.md` file has a Flight Operations section:

1. **If CLAUDE.md doesn't exist**, create it with the Flight Operations section below
2. **If CLAUDE.md exists but lacks a Flight Operations section**, append the section below
3. **If CLAUDE.md already has a Flight Operations section**, leave it unchanged — unless migration 007 is pending, in which case replace the section's contents with the current snippet (that migration exists precisely to refresh this section)

#### 7a. Fix Stale Path References

If migrations were applied in Step 2, scan the project's `CLAUDE.md` for stale path references within the Flight Operations section and fix them:

- Replace `.flight-ops/` → `.flightops/`
- Replace `phases/` → `agent-crews/` (only within Flight Operations context)

This ensures the CLAUDE.md instructions point to the correct post-migration paths.

The Flight Operations section:

```markdown
## Flight Operations

This project uses [Flight Control](https://github.com/msieurthenardier/mission-control) via the `mission-control` Claude Code plugin. Skills are invoked as `/mission-control:<skill>` from this project's root.

**Before any mission/flight/leg/squawk work, read these files in order:**
1. `.flightops/README.md` — What the flightops directory contains
2. `.flightops/FLIGHT_OPERATIONS.md` — **The workflow you MUST follow**
3. `.flightops/ARTIFACTS.md` — Where all artifacts are stored
4. `.flightops/agent-crews/` — Project crew definitions for each phase (read the relevant crew file)

**Flight Director role.** When a human says a leg is ready to implement, invoke `/mission-control:agentic-workflow`. Do not read the leg spec, plan execution steps, or execute commands directly — the skill orchestrates separate Developer and Reviewer agents and emits `[HANDOFF:...]` and `[COMPLETE:...]` signals. Planning skills (`/mission-control:mission`, `/mission-control:flight`, debriefs, `/mission-control:routine-maintenance`) produce artifacts only and never modify source files.

**Spawned agents** (Developer, Reviewer, Architect, Executor, Validator) do not have the Skill tool. Everything they need is in `.flightops/`; they must not try to load plugin skills.

**Methodology drift.** A SessionStart notice from the plugin means this project is behind the installed plugin version. Recommend `/mission-control:preflight-check` or `/mission-control:init-project` to bring it current; never apply migrations by hand.
```

### 8. Post-Sync Instructions

After creating or updating the directory, inform the user:

> "Restart Claude Code in this project to pick up the new flight operations references."

This ensures Claude Code loads the new files into its context.

## Output

This skill creates/updates the following at the project root:

```
{project-root}/
├── CLAUDE.md                  # Updated with Flight Operations section
└── .flightops/               # Hidden directory for Flight Control
    ├── README.md              # Explains the directory purpose
    ├── FLIGHT_OPERATIONS.md   # Quick reference for implementation (synced)
    ├── ARTIFACTS.md           # Artifact system configuration (project-specific)
    └── agent-crews/           # Project crew definitions (project-specific)
        ├── mission-design.md
        ├── flight-design.md
        ├── leg-execution.md
        ├── flight-debrief.md
        ├── mission-debrief.md
        ├── routine-maintenance.md
        └── behavior-tests-execution.md
```

## File Sync Behavior

| File | Synced on update? | Notes |
|------|-------------------|-------|
| CLAUDE.md | Append only | Adds Flight Operations section if missing; refreshed by migration 007 |
| README.md | Yes | Methodology reference |
| FLIGHT_OPERATIONS.md | Yes | Methodology reference |
| ARTIFACTS.md | No | Created once from template, then project-specific |
| agent-crews/*.md | Ask on re-run | Created from defaults; on re-run, user can choose to update to latest defaults |

## Guidelines

### Don't Over-Prompt

If everything is `current`, just inform the user briefly and move on. No confirmation needed.

### Respect ARTIFACTS.md

Never overwrite ARTIFACTS.md — it may contain project-specific customizations. Only create it if missing.

### Keep It Quick

This is a setup step, not the main work. Complete it efficiently so the user can proceed to their actual task.
