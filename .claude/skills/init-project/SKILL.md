---
name: init-project
description: Initialize a project for Flight Control. Creates flight_operations directory with methodology reference and artifact configuration. Run before using /mission, /flight, /leg, or /flight-review on a new project.
---

# Project Initialization

Prepare a project for Flight Control by creating the `flight_operations/` directory with methodology references and artifact configuration.

## When to Use

Run `/init-project` when:
- Starting to use Flight Control on a new project
- You suspect the flight_operations reference may be outdated
- Another skill indicates the reference needs to be synced

## Workflow

### 1. Identify Target Project

1. **Read `projects.md`** to find the project's path, remote, and description
2. If the project isn't listed, ask the user for:
   - Project name/slug
   - Filesystem path
   - Brief description
3. Optionally offer to add the project to `projects.md`

### 2. Detect Directory Naming Convention

Analyze the target project to determine the appropriate naming style:

1. **Check existing directories** in project root for patterns:
   - `snake_case` → use `flight_operations/`
   - `kebab-case` → use `flight-operations/`
   - `camelCase` → use `flightOperations/`
   - `PascalCase` → use `FlightOperations/`
2. **Check config files** for hints (package.json conventions, Cargo.toml, etc.)
3. **Default to kebab-case** if no clear convention exists

### 3. Check Sync Status

Run the hash comparison script to determine sync status:

```bash
bash "${SKILL_DIR}/check-sync.sh" \
  "${SKILL_DIR}" \
  "{target-project}/{detected-dir-name}"
```

The script outputs one of:
- `missing` - Directory doesn't exist in target project
- `outdated` - Directory exists but files differ from source
- `current` - All files are up-to-date

### 4. Prompt and Sync Methodology Files

Based on the status:

**If `missing`**:
> "Flight operations directory not found. Create `{project}/{dir-name}/` with methodology references?"

**If `outdated`**:
> "Flight operations references in {project} are outdated. Update?"

**If `current`**:
> "Flight operations references are up-to-date in {project}."

If the user confirms, create/update the directory:

```bash
mkdir -p "{target-project}/{dir-name}"
cp "${SKILL_DIR}/FLIGHT_OPERATIONS.md" "{target-project}/{dir-name}/"
cp "${SKILL_DIR}/README.md" "{target-project}/{dir-name}/"
```

### 5. Configure Artifact System (New Projects Only)

**Only if ARTIFACTS.md doesn't exist**, ask the user to select an artifact system:

> "How should mission, flight, and leg artifacts be stored?"

Available templates:
- **files** — Markdown files in the repository (`templates/ARTIFACTS-files.md`)
- **jira** — Jira issues: Epics, Stories, Sub-tasks (`templates/ARTIFACTS-jira.md`)

Copy the selected template:

```bash
cp "${SKILL_DIR}/templates/ARTIFACTS-{selection}.md" \
   "{target-project}/{dir-name}/ARTIFACTS.md"
```

**If ARTIFACTS.md already exists**, do not modify it — it's project-specific and may have been customized.

### 6. Update CLAUDE.md

Check if the project's `CLAUDE.md` file references the flight operations directory:

1. **If CLAUDE.md doesn't exist**, create it with a Flight Operations section
2. **If CLAUDE.md exists but lacks a Flight Operations section**, append one
3. **If CLAUDE.md already has a Flight Operations section**, leave it unchanged

Add this section (adjusting the directory name to match the project's convention):

```markdown
## Flight Operations

This project uses the [Flight Control](https://github.com/anthropics/flight-control) methodology. When implementing missions, flights, or legs, you MUST strictly follow the workflow defined in `{dir-name}/FLIGHT_OPERATIONS.md`.
```

### 7. Post-Sync Instructions

After creating or updating the directory, inform the user:

> "If you have Claude Code running in {project}, restart it to pick up the new flight operations references."

This ensures Claude Code loads the new files into its context when working in the target project.

## Output

This skill creates/updates the following at project root:

```
{project}/
├── CLAUDE.md                  # Updated with Flight Operations section
└── {flight-operations-dir}/   # Named per project convention
    ├── README.md              # Explains the directory purpose
    ├── FLIGHT_OPERATIONS.md   # Quick reference for implementation (synced)
    └── ARTIFACTS.md           # Artifact system configuration (project-specific)
```

## File Sync Behavior

| File | Synced on update? | Notes |
|------|-------------------|-------|
| CLAUDE.md | Append only | Adds Flight Operations section if missing |
| README.md | Yes | Methodology reference |
| FLIGHT_OPERATIONS.md | Yes | Methodology reference |
| ARTIFACTS.md | No | Created once from template, then project-specific |

## Guidelines

### Detect Convention First

Always analyze the project's naming patterns before suggesting a directory name. Consistency matters.

### Don't Over-Prompt

If everything is `current`, just inform the user briefly and move on. No confirmation needed.

### Respect ARTIFACTS.md

Never overwrite ARTIFACTS.md — it may contain project-specific customizations. Only create it if missing.

### Keep It Quick

This is a setup step, not the main work. Complete it efficiently so the user can proceed to their actual task.
