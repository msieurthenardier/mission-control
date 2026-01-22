# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flight Control is an AI-first software development lifecycle methodology using aviation metaphors. It organizes work into three hierarchical levels:

- **Missions** (human-optimized) — Define outcomes in human terms, days-to-weeks scope
- **Flights** (balanced) — Technical specifications with pre/in/post-flight checklists, hours-to-days scope
- **Legs** (AI-optimized) — Structured implementation steps with explicit acceptance criteria, minutes-to-hours scope

This repository contains the methodology documentation and Claude Code skills for interactive planning.

## Claude Code Skills

Five skills automate the planning and review workflow:

| Skill | Purpose | Output (in target project) |
|-------|---------|----------------------------|
| `/init-project` | Initialize a project for Flight Control | Creates `{flight-operations}/` directory |
| `/mission` | Create outcome-driven missions through research and interview | `missions/{slug}/mission.md` |
| `/flight` | Create technical flight specs from missions | `missions/{slug}/flights/{NN}-{slug}/flight.md` |
| `/leg` | Generate implementation guidance for LLM execution | `missions/{slug}/flights/{NN}-{slug}/legs/{NN}-{slug}.md` |
| `/flight-review` | Post-flight analysis for continuous improvement | `missions/{slug}/flights/{NN}-{slug}/flight-review.md` |

Run `/init-project` before using the other skills on a new project to create the flight operations reference directory and configure the artifact system.

**Artifact Systems:** Each project defines how artifacts are stored in `ARTIFACTS.md` (e.g., markdown files, Jira tickets). Skills read this configuration and adapt their output accordingly.

**IMPORTANT: Skills produce documentation only.** When running `/mission`, `/flight`, `/leg`, or `/flight-review`:
- **NEVER implement code changes** — only create/update markdown documentation files
- **NEVER modify source files** in the target project (no `.rs`, `.ts`, `.tsx`, `.json`, etc.)
- The leg document contains implementation guidance for a separate execution phase
- Implementation happens later, in a dedicated session within the target project

## Projects Registry

The `projects.md` file in this repository catalogs all active projects on this device. When using the `/mission`, `/flight`, or `/leg` skills:

1. **Read `projects.md` first** to find the target project's path, remote, and description
2. **Create all artifacts in the target project** (`{target-project}/missions/...`) — not in mission-control
3. **Use the project path from the registry** to locate existing missions or create new ones

The registry provides:
- Project slug and description
- Filesystem path (e.g., `~/projects/my-app`)
- Git remote and branch
- Optional stack and status information

## Directory Structure

Within each target project:

```
{target-project}/
├── {flight-operations}/       # Named per project convention (kebab/snake/camel)
│   ├── README.md              # Directory purpose and usage
│   ├── FLIGHT_OPERATIONS.md   # Quick reference for implementation (synced)
│   └── ARTIFACTS.md           # Artifact system configuration (project-specific)
└── missions/                  # Default location for file-based artifacts
    └── {mission-slug}/
        ├── mission.md
        ├── mission-review.md
        └── flights/
            └── {NN}-{flight-slug}/
                ├── flight.md
                ├── flight-log.md
                ├── flight-review.md
                └── legs/
                    └── {NN}-{leg-slug}.md
```

**Note:** The `missions/` structure above is for file-based artifact storage. Projects using Jira or other systems will define their artifact locations in `ARTIFACTS.md`.

## Lifecycle States

- **Missions**: `planning` → `active` → `completed` (or `aborted`)
- **Flights**: `planning` → `ready` → `in-flight` → `landed` (or `diverted`)
- **Legs**: `queued` → `in-progress` → `review` → `completed` (or `blocked`)

## Key Principles

1. **Outcome over activity**: Frame missions around results, not tasks
2. **Immutability after start**: Never modify legs once `in-progress`; create new ones instead
3. **Pre-flight rigor**: Resolve all open questions and verify prerequisites before execution
4. **Explicit criteria**: Acceptance criteria must be binary, observable, and complete
5. **Log during flight**: Record decisions, deviations, and anomalies in the flight log for continuity and future leg creation

## Sizing Guidelines

| Level | Duration | Typical Count |
|-------|----------|---------------|
| Mission | Days to weeks | 5-7 flights |
| Flight | 1-3 days | 3-8 legs |
| Leg | Minutes to hours | Atomic, independently completable |

## Public Repository

This is a public repository. Keep all committed content anonymized:

- **No personal paths** — Use generic examples like `~/projects/my-app`, not actual home directories
- **No usernames** — Use placeholders like `username` in examples
- **No project-specific details** — Keep examples generic
- `projects.md` is gitignored for this reason — it contains local paths and is not committed
