# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flight Control is an AI-first software development lifecycle methodology using aviation metaphors. It organizes work into three hierarchical levels:

- **Missions** (human-optimized) — Define outcomes in human terms, days-to-weeks scope
- **Flights** (balanced) — Technical specifications with pre/in/post-flight checklists, hours-to-days scope
- **Legs** (AI-optimized) — Structured implementation steps with explicit acceptance criteria, minutes-to-hours scope

This repository contains the methodology documentation and Claude Code skills for interactive planning.

## Claude Code Skills

Six skills automate the planning and debrief workflow:

| Skill | Purpose |
|-------|---------|
| `/init-project` | Initialize a project for Flight Control (creates `.flight-ops/` directory) |
| `/mission` | Create outcome-driven missions through research and interview |
| `/flight` | Create technical flight specs from missions |
| `/leg` | Generate implementation guidance for LLM execution |
| `/flight-debrief` | Post-flight analysis for continuous improvement |
| `/mission-debrief` | Post-mission retrospective for outcomes assessment |

Run `/init-project` before using the other skills on a new project to create the flight operations reference directory and configure the artifact system.

**Artifact Systems:** Each project defines how artifacts are stored in `.flight-ops/ARTIFACTS.md`. Skills read this configuration and adapt their output accordingly.

**IMPORTANT: Skills produce documentation only.** When running these skills:
- **NEVER implement code changes** — only create/update artifacts
- **NEVER modify source files** in the target project (no `.rs`, `.ts`, `.tsx`, `.json`, etc.)
- The leg document contains implementation guidance for a separate execution phase
- Implementation happens later, in a dedicated session within the target project

## Projects Registry

The `projects.md` file in this repository catalogs all active projects on this device. When using skills:

1. **Read `projects.md` first** to find the target project's path, remote, and description
2. **Read `.flight-ops/ARTIFACTS.md`** in the target project to determine artifact locations
3. **Create all artifacts in the target project** — not in mission-control

The registry provides:
- Project slug and description
- Filesystem path (e.g., `~/projects/my-app`)
- Git remote and branch
- Optional stack and status information

## Flight Operations Directory

Every project using Flight Control has a `.flight-ops/` directory:

```
{target-project}/
└── .flight-ops/
    ├── README.md              # Directory purpose and usage
    ├── FLIGHT_OPERATIONS.md   # Quick reference for implementation (synced)
    └── ARTIFACTS.md           # Artifact system configuration (project-specific)
```

The `ARTIFACTS.md` file defines where and how all artifacts are stored.

## Business Objects

Flight Control defines these business objects (artifacts):

| Object | Purpose |
|--------|---------|
| Mission | Outcome-driven goal definition |
| Mission Briefing | Pre-mission summary for stakeholder alignment |
| Mission Debrief | Post-mission retrospective |
| Flight | Technical specification with checklists |
| Flight Log | Running record during execution |
| Flight Briefing | Pre-flight summary for crew alignment |
| Flight Debrief | Post-flight analysis |
| Leg | Atomic implementation step |

## Lifecycle States

- **Missions**: `planning` → `active` → `completed` (or `aborted`)
- **Flights**: `planning` → `ready` → `in-flight` → `landed` (or `diverted`)
- **Legs**: `queued` → `in-progress` → `review` → `completed` (or `blocked`)

## Key Principles

1. **Outcome over activity**: Frame missions around results, not tasks
2. **Phase gates require confirmation**: Complete each planning phase before starting the next:
   - Missions must be fully agreed before designing flights
   - Flights must be fully agreed before designing legs
   - Never skip ahead — get explicit user confirmation at each transition
3. **Immutability after start**: Never modify legs once `in-progress`; create new ones instead
4. **Pre-flight rigor**: Resolve all open questions and verify prerequisites before execution
5. **Explicit criteria**: Acceptance criteria must be binary, observable, and complete
6. **Log during flight**: Record decisions, deviations, and anomalies in the flight log

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
