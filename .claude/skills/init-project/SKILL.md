---
name: init-project
description: Initialize a project for Flight Control. Creates .flight-ops directory with methodology reference and artifact configuration. Run before using other Flight Control skills on a new project.
---

# Project Initialization

Prepare a project for Flight Control by creating the `.flight-ops/` directory with methodology references and artifact configuration.

## When to Use

Run `/init-project` when:
- Starting to use Flight Control on a new project
- You suspect the .flight-ops reference may be outdated
- Another skill indicates the reference needs to be synced

## Workflow

### 1. Identify Target Project

1. **Read `projects.md`** to find the project's path, remote, and description
2. If the project isn't listed, ask the user for:
   - Project name/slug
   - Filesystem path
   - Brief description
3. Optionally offer to add the project to `projects.md`

### 2. Check Sync Status

Run the hash comparison script to determine sync status:

```bash
bash "${SKILL_DIR}/check-sync.sh" \
  "${SKILL_DIR}" \
  "{target-project}/.flight-ops"
```

The script outputs one of:
- `missing` - Directory doesn't exist in target project
- `outdated` - Directory exists but files differ from source
- `current` - All files are up-to-date

### 3. Prompt and Sync Methodology Files

Based on the status:

**If `missing`**:
> "Flight operations directory not found. Create `{project}/.flight-ops/` with methodology references?"

**If `outdated`**:
> "Flight operations references in {project} are outdated. Update?"

**If `current`**:
> "Flight operations references are up-to-date in {project}."

If the user confirms, create/update the directory:

```bash
mkdir -p "{target-project}/.flight-ops"
cp "${SKILL_DIR}/FLIGHT_OPERATIONS.md" "{target-project}/.flight-ops/"
cp "${SKILL_DIR}/README.md" "{target-project}/.flight-ops/"
```

### 4. Configure Artifact System (New Projects Only)

**Only if ARTIFACTS.md doesn't exist**, ask the user to select an artifact system:

> "How should mission, flight, and leg artifacts be stored?"

Available templates:
- **files** — Markdown files in the repository (`templates/ARTIFACTS-files.md`)
- **jira** — Jira issues: Epics, Stories, Sub-tasks (`templates/ARTIFACTS-jira.md`)

#### 4a. Check for Setup Questions

After the user selects a template, read the template file and check if it contains a `## Setup Questions` section with a table of questions.

If setup questions exist:
1. Parse the questions from the table (first column contains the questions)
2. Ask the user each question interactively
3. Replace the placeholder answers in the table with the user's responses

#### 4b. Copy and Populate Template

Copy the selected template, with answers populated if setup questions were asked:

```bash
cp "${SKILL_DIR}/templates/ARTIFACTS-{selection}.md" \
   "{target-project}/.flight-ops/ARTIFACTS.md"
```

If setup questions were answered, update the ARTIFACTS.md file to replace the placeholder answers with the user's responses.

**If ARTIFACTS.md already exists**, do not modify it — it's project-specific and may have been customized.

### 5. Update CLAUDE.md

Check if the project's `CLAUDE.md` file references the flight operations directory:

1. **If CLAUDE.md doesn't exist**, create it with a Flight Operations section
2. **If CLAUDE.md exists but lacks a Flight Operations section**, append one
3. **If CLAUDE.md already has a Flight Operations section**, leave it unchanged

Add this section:

```markdown
## Flight Operations

This project uses the [Flight Control](https://github.com/anthropics/flight-control) methodology. When implementing missions, flights, or legs, you MUST strictly follow the workflow defined in `.flight-ops/FLIGHT_OPERATIONS.md`.
```

### 6. Post-Sync Instructions

After creating or updating the directory, inform the user:

> "If you have Claude Code running in {project}, restart it to pick up the new flight operations references."

This ensures Claude Code loads the new files into its context when working in the target project.

## Output

This skill creates/updates the following at project root:

```
{project}/
├── CLAUDE.md                  # Updated with Flight Operations section
└── .flight-ops/               # Hidden directory for Flight Control
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

### Don't Over-Prompt

If everything is `current`, just inform the user briefly and move on. No confirmation needed.

### Respect ARTIFACTS.md

Never overwrite ARTIFACTS.md — it may contain project-specific customizations. Only create it if missing.

### Keep It Quick

This is a setup step, not the main work. Complete it efficiently so the user can proceed to their actual task.
