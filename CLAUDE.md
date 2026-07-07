# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Invocation Context

You may be invoked by:
- **A human** — Interactive session, ask questions freely
- **An LLM orchestrator** — Run `/agentic-workflow` to drive multi-agent flight execution

When orchestrated, you are the **Flight Director** — responsible for driving execution, coordinating agents, and making go/no-go decisions. Emit signals like `[HANDOFF:review-needed]` and `[COMPLETE:leg]` at appropriate points. The orchestrator monitors your output for these markers.

**When a human says a leg is ready to implement**, invoke `/agentic-workflow`. Do not read the leg spec, do not plan execution steps, do not execute commands directly. You become the orchestrator by loading the skill.

### Loading Skills in Non-Interactive Contexts

**The Skill tool is ONLY available in interactive human sessions.** If you are a spawned agent, running via `claude -p`, or inside a container/SDK — you do NOT have the Skill tool. Do not attempt to call it.

To execute a skill, read its SKILL.md file directly and follow the workflow:

```
Read .claude/skills/{skill-name}/SKILL.md and execute the workflow described there.
```

**All Flight Control skills** (listed in the table below) **live in this repository** (mission-control), under `.claude/skills/`. The Flight Director runs from the mission-control directory, so relative `.claude/skills/` paths in skill docs resolve here. Target projects may have their own unrelated skills in their own `.claude/skills/` directories — those are separate.

## First-Contact Check

If `projects.md` does not exist in this repository, suggest running `/init-mission-control` to set up the projects registry before proceeding with any other skills.

### Per-Project Drift Check

A `SessionStart` hook (`.claude/hooks/check-project-drift.sh`, wired in `.claude/settings.json`) scans every registered project at session start and injects a notice listing any with pending methodology migrations. When that notice is present and the user engages one of the listed projects, tell them it's behind the current methodology and **recommend running `/init-project`** to apply the migrations — then continue with what they asked. Recommend only; never apply migrations yourself (`/init-project` owns that, with confirmation).

To check a single project on demand, run the detector directly:

```bash
bash .claude/skills/init-project/check-drift.sh \
  .claude/skills/init-project \
  "{target-project}/.flightops"
```

## Project Overview

Flight Control is an AI-first software development lifecycle methodology using aviation metaphors. It organizes work into three hierarchical levels:

- **Missions** (human-optimized) — Define outcomes in human terms, days-to-weeks scope
- **Flights** (balanced) — Technical specifications with pre/in/post-flight checklists, hours-to-days scope
- **Legs** (AI-optimized) — Structured implementation steps with explicit acceptance criteria, minutes-to-hours scope

Alongside the planning hierarchy, Flight Control includes **behavior tests** — Zephyr-style multi-step acceptance tests run with two live AI agents (an Executor that performs each step's actions and an independent Validator that judges each step's expected results) using the **Witnessed** pattern. Behavior tests verify real-environment behavior (UI flows, multi-component interactions, AI agent behavior) that doesn't fit unit/integration tests. Specs are authored inline during planning conversations and run via the `/behavior-test` skill. See `.claude/skills/behavior-test/AUTHORING.md` for the authoring guide.

This repository contains the methodology documentation and Claude Code skills for interactive planning.

## Claude Code Skills

Twelve skills automate the planning, execution, debrief, oversight, and acceptance-test workflows:

| Skill | Purpose |
|-------|---------|
| `/init-mission-control` | Onboard to Mission Control (set up `projects.md` registry) |
| `/init-project` | Initialize a project for Flight Control (creates `.flightops/` directory) |
| `/mission` | Create outcome-driven missions through research and interview |
| `/flight` | Create technical flight specs from missions |
| `/leg` | Generate implementation guidance for LLM execution |
| `/agentic-workflow` | Drive multi-agent flight execution (design per leg, batch implement, single review and commit) |
| `/flight-debrief` | Post-flight analysis for continuous improvement |
| `/mission-debrief` | Post-mission retrospective for outcomes assessment |
| `/routine-maintenance` | Post-mission codebase health assessment and maintenance recommendation |
| `/preflight-check` | Verify all projects have current methodology files and crew definitions |
| `/daily-briefing` | Cross-project status report with health assessment and methodology insights |
| `/behavior-test` | Run a behavior test — spawn two live agents (Executor + Validator) using the Witnessed pattern (every action judged by an independent agent), drive them through the spec's Zephyr-style Action \| Expected Result table with mid-test communication, write a run log with evidence. For real-environment verification (UI / API / shell / filesystem) that doesn't fit unit tests. Specs are authored inline during planning conversations — see `.claude/skills/behavior-test/AUTHORING.md` for the authoring guide. |

Run `/init-project` before using the other skills on a new project to create the flight operations reference directory and configure the artifact system.

**Artifact Systems:** Each project defines how artifacts are stored in `.flightops/ARTIFACTS.md`. Skills read this configuration and adapt their output accordingly.

**IMPORTANT: Planning skills produce documentation only.** `/init-project`, `/mission`, `/flight`, `/leg`, `/flight-debrief`, `/mission-debrief`, and `/routine-maintenance` must:
- **NEVER implement code changes** — only create/update artifacts
- **NEVER modify source files** in the target project (no `.rs`, `.ts`, `.tsx`, `.json`, etc.)

`/agentic-workflow` orchestrates implementation by spawning separate agents that execute code changes in the target project. The orchestrator itself never modifies source files directly.

> **Phase gates require confirmation.** Missions must be fully agreed before designing
> flights. Flights must be fully agreed before designing legs. Never skip ahead — get
> explicit user confirmation at each transition.

## Projects Registry

The `projects.md` file in this repository catalogs all active projects on this device. When using skills:

1. **Read `projects.md` first** to find the target project's path, remote, and description
2. **Read `.flightops/ARTIFACTS.md`** in the target project to determine artifact locations
3. **Create all artifacts in the target project** — not in mission-control

The registry provides:
- Project slug and description
- Filesystem path (e.g., `~/projects/my-app`)
- Git remote
- Optional stack and status information

## Lifecycle States

- **Missions**: `planning` → `active` → `completed` (or `aborted`)
- **Flights**: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`)
- **Legs**: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`)

## Skill–Project Boundary

Mission Control skills run in projects whose owners can customize `.flightops/ARTIFACTS.md` and `.flightops/agent-crews/*.md` freely. Skills must not couple to project-owned shape:

- **Do not read project-owned artifacts by section heading.** When a skill needs to extract information from a prior debrief, maintenance report, or other project-owned artifact, frame the instruction by intent — what the agent is looking for — and let the agent locate it within whatever structure the project uses. Reading by literal heading name (e.g. `## Action Items`, `## Test Suite Timing`) breaks silently the moment a project owner renames or removes that section.
- **Do not write into project-owned artifacts at named anchors.** When a skill inserts content into a project artifact, describe the destination semantically ("in the section the project uses for X") rather than by literal heading. If the skill is appending a new section, suggest a heading without prescribing it as a contract.
- **Do not rely on crew prompt files to carry skill-required instructions.** The Flight Director must issue per-spawn instructions directly from the SKILL.md, even when the crew file also contains an overlapping prompt. Crew files are project-modifiable scaffolding; SKILL.md is the protocol.
- **Defer to ARTIFACTS.md for the whole persistence procedure, not two named fields.** A skill reads ARTIFACTS.md for how the project handles each artifact — storage location, format, and any actions the project defines at create and transition time (opening a ticket, posting a notification). Don't extract a capped "location and format"; that silently drops project-defined side-effects, and don't hardcode artifact paths. Protocol — state values, lifecycle, taxonomy, invariants — lives in the skills, never in ARTIFACTS.md.

## Project Information Stays in Project Artifacts

**Never store project-specific information in Claude Code memories** — not in mission-control's memory directory, not in any project's memory directory. Project-specific issues, bugs, technical debt, design gaps, known issues, and lessons learned belong exclusively in the project's own Flight Control artifacts:

- **Flight logs** — runtime decisions, deviations, anomalies
- **Flight debriefs** — post-flight analysis, recommendations, action items
- **Mission known issues** — cross-flight concerns discovered during execution
- **Design decision sections** — in flight and mission artifacts

Mission-control is a neutral methodology tool. Its memory (if used at all) is reserved for methodology preferences, user collaboration preferences, and cross-cutting tooling notes — never for project-specific content.

## Never Leak Operator Identity

Never write the operator's machine username or absolute home paths (`/home/<user>/...`, `/Users/<user>/...`, `C:\Users\<user>\...`) into any generated content — artifacts, code, tests, commit messages, PR descriptions, log excerpts pasted into docs.

Use repo-relative paths (`src/foo/bar.ts`), `~/projects/<slug>/...`, or `<username>` placeholders instead. If you spot a leaked path in existing content, flag it and offer to scrub.

## Public Repository

This is a public repository. Keep all committed content anonymized:

- **No personal paths** — Use generic examples like `~/projects/my-app`, not actual home directories
- **No usernames** — Use placeholders like `username` in examples
- **No project-specific details** — Keep examples generic
- `projects.md` is gitignored for this reason — it contains local paths and is not committed
