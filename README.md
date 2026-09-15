# Flight Control

An AI-first software development lifecycle methodology using aviation metaphors to bridge human intent and AI execution.

## What is Mission Control?

Mission Control is the Claude Code **plugin** that ships Flight Control. Install it once and every project you open gets the same planning, execution, and debrief workflow, whatever its stack.

- **Shared methodology** — Apply structured planning regardless of project differences
- **Claude Code skills** — Interactive tools for mission, flight, leg, and squawk work, invoked as `/mission-control:<skill>`
- **Multi-agent execution** — A Flight Director session orchestrates separate Developer, Reviewer, and Architect agents

Skills run from the project's own root. Artifacts (missions, flights, legs, squawks) live in the project, configured by its `.flightops/` directory. The plugin holds the methodology and skills; your project holds the work.

## The Aviation Model

Flight Control organizes work into three hierarchical levels, each optimized for its primary audience:

```
Mission (human-optimized)
  └── Flight (balanced)
        └── Leg (AI-optimized)
```

- **Missions** define outcomes in human terms—what success looks like and why it matters
- **Flights** translate outcomes into technical specifications with planning checklists
- **Legs** provide structured, specific instructions optimized for AI consumption

Beside the hierarchy sits the **squawk** — a standalone artifact for work too small to plan. In aviation, a squawk is a defect logged in the aircraft's logbook and cleared by a mechanic, signed off by someone other than the reporter. Here it covers a single bug fix or routine servicing update: no mission, no flight, no leg, no debrief. See [Squawks](docs/squawks.md).

## Why Aviation?

Aviation succeeds through layered planning and clear handoffs. Pilots follow flight plans but improvise when conditions demand it—weather, emergencies, ATC instructions. Structured planning enables effective improvisation by providing a baseline to deviate from and return to. Similarly, Flight Control separates strategic intent (missions) from tactical execution (legs), with flights serving as the translation layer.

## Agentic Workflow

**LLM orchestrators**: Run `/mission-control:agentic-workflow` to drive multi-agent flight execution with Claude Code. The skill designs and implements each leg in turn, then runs a single code review and commit across the whole flight, using separate Claude instances for the Flight Director, Developer, and Reviewer roles.

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A project on disk with a git remote, initialized with Claude Code (`claude /init`)

### Install the plugin

From any Claude Code session:

```
/plugin marketplace add msieurthenardier/mission-control
/plugin install mission-control@flight-control
```

To develop the plugin from a local clone instead, start Claude Code with `claude --plugin-dir /path/to/mission-control`.

### Walkthrough

All steps run in Claude Code from your project's root directory.

1. **Initialize your project** — Run `/mission-control:init-project`. This creates `.flightops/` with artifact configuration, methodology reference, and crew definitions, and adds a Flight Operations section to your `CLAUDE.md`.

2. **Review agent crew files** — Check the files in `.flightops/agent-crews/`. These define the crew composition (roles, models, prompts) for each phase. Customize them to your needs.

3. **Create a mission** — Run `/mission-control:mission`. This interviews you about desired outcomes and creates a mission artifact.

4. **Design a flight** — Run `/mission-control:flight` to break the mission into a technical specification with pre/in/post-flight checklists.

5. **Execute** — Run `/mission-control:agentic-workflow` to drive multi-agent implementation. This designs and implements each leg in turn, then reviews and commits the whole flight in one pass at the end.

6. **Debrief** — Run `/mission-control:flight-debrief` and `/mission-control:mission-debrief` after completion to capture lessons learned.

### Staying current

When the plugin updates, projects initialized against an older version drift. A SessionStart hook prints a one-line notice in any project that is behind; run `/mission-control:preflight-check` for the full report and `/mission-control:init-project` to apply migrations and re-sync methodology files.

If you used Flight Control before it was a plugin — a cloned `mission-control` checkout with a `projects.md` registry — see [Migrating to the plugin](docs/migrating-to-the-plugin.md).

## Documentation

1. **[Overview](docs/overview.md)** — Philosophy and principles behind Flight Control
2. **[Missions](docs/missions.md)** — Writing outcome-driven mission statements
3. **[Flights](docs/flights.md)** — Creating technical specifications with pre/post checklists
4. **[Flight Logs](docs/flight-logs.md)** — Recording execution progress and decisions
5. **[Legs](docs/legs.md)** — Structuring AI-optimized implementation steps
6. **[Squawks](docs/squawks.md)** — Small standalone fixes that don't warrant a mission
7. **[Workflow](docs/workflow.md)** — End-to-end flow from mission to completion
8. **[Migrating to the plugin](docs/migrating-to-the-plugin.md)** — Moving from the pre-plugin checkout and `projects.md` registry

## Core Concepts

### The Audience Gradient

Documentation becomes progressively more structured as it moves down the hierarchy:

| Level | Audience | Style |
|-------|----------|-------|
| Mission | Humans, stakeholders | Narrative prose, outcome-focused |
| Flight | Developers, AI | Technical spec with checklists |
| Leg | AI agents | Structured format, explicit criteria |

### Lifecycle States

Each level tracks progress through defined states:

- **Missions**: `planning` → `active` → `completed` (or `aborted`)
- **Flights**: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`)
- **Legs**: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`)
- **Squawks**: `open` → `in-progress` → `completed` (or `deferred`, `escalated`) — a squawk has no planning phase, so it does not share the unified lifecycle

### Scaling

Flight Control scales from solo developers to teams. The methodology provides structure and continuity across sessions regardless of team size.

## Artifact Organization

The hierarchy nests naturally:

```
Mission
├── Mission Debrief
└── Flight
    ├── Flight Log
    ├── Flight Briefing
    ├── Flight Debrief
    └── Leg

Squawk        (standalone — no parent, no debrief)
```

By default, artifacts are stored as version-controlled markdown files in your project's repository. Each project's `.flightops/ARTIFACTS.md` describes where and how artifacts live — skills read this file to determine locations and formats. You can adapt it to other backends (Jira, Linear, GitHub Issues, hybrid setups) by editing this file directly; only the markdown-files template ships out of the box.

## Claude Code Skills

All skills are namespaced under the plugin and run from the project root:

| Skill | Purpose |
|-------|---------|
| `/mission-control:init-project` | Initialize the current project for Flight Control; apply methodology migrations |
| `/mission-control:preflight-check` | Full drift diagnosis of the current project against the installed plugin |
| `/mission-control:mission` | Create outcome-driven missions through research and interview |
| `/mission-control:flight` | Create technical flight specs from missions |
| `/mission-control:agentic-workflow` | Drive multi-agent flight execution |
| `/mission-control:squawk` | Log and complete small standalone fixes — one defect or one routine update, no mission required |
| `/mission-control:behavior-test` | Run a behavior test — live two-agent execution (Executor + Validator) against real UI / API / shell / filesystem, Zephyr-style Action \| Expected Result spec. Specs are authored inline during planning conversations (see `skills/behavior-test/AUTHORING.md`). |
| `/mission-control:flight-debrief` | Post-flight analysis for continuous improvement |
| `/mission-control:mission-debrief` | Post-mission retrospective for outcomes assessment |
| `/mission-control:routine-maintenance` | Between-mission codebase health assessment |

## Plugin Layout

```
.claude-plugin/
├── plugin.json          # Plugin manifest
└── marketplace.json     # Lets /plugin install resolve this repo directly
skills/<name>/SKILL.md   # One directory per skill; init-project also carries the
                         # synced methodology files, templates, crew defaults,
                         # migrations registry, and drift detector
hooks/
├── hooks.json           # SessionStart drift notice
└── check-project-drift.sh
docs/                    # Methodology documentation
```

## Recommended Workflow

All work runs from a single **Flight Director** session in the project root. The Flight Director handles planning directly and spawns agents for implementation, review, and commits. Each spawned agent gets a clean context with only the information it needs, while the Flight Director maintains continuity across the entire flight.

### Context Strategy

- **Flight Director**: Long-running session spanning an entire flight — accumulates knowledge across legs, orchestrates all work
- **Spawned agents**: Fresh context per task — designed with precise instructions and the relevant artifacts, inherit the project root as their working directory

No second interactive session is needed.

### Why This Matters

A single orchestrating session eliminates context drift between planning and execution. The Flight Director sees every leg's outcome and carries that knowledge forward into the next design. Spawned agents get clean, focused contexts — they don't need flight-wide memory because the Flight Director provides exactly the context they need. Artifacts stay synchronized because one session owns the full lifecycle.

## License

[MIT](LICENSE)
