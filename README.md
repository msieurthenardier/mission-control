# Flight Control

An AI-first software development lifecycle methodology using aviation metaphors to bridge human intent and AI execution.

## What is Mission Control?

This repository is a **centralized command center** for managing multiple projects in parallel. Each project may have its own stack, systems, and constraints, but mission-control provides a consistent workflow and orchestration layer across all of them.

- **Project registry** — Track active projects with paths, remotes, and configurations
- **Shared methodology** — Apply structured planning regardless of project differences
- **Claude Code skills** — Interactive tools for mission, flight, and leg creation

Artifacts (missions, flights, legs) are created in target projects, not here. Mission-control holds the methodology, skills, and coordination—your projects hold the work.

Development crews remain essential. AI can automate much of the implementation, but technical oversight ensures quality and alignment with intent.

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

## Why Aviation?

Aviation succeeds through layered planning and clear handoffs. Pilots follow flight plans but improvise when conditions demand it—weather, emergencies, ATC instructions. Structured planning enables effective improvisation by providing a baseline to deviate from and return to. Similarly, Flight Control separates strategic intent (missions) from tactical execution (legs), with flights serving as the translation layer.

## Agentic Workflow

**LLM orchestrators**: Run `/agentic-workflow` to drive multi-agent flight execution with Claude Code. The skill orchestrates the full leg cycle — design, implement, review, commit — using three separate Claude instances.

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A project on disk with a git remote

### Walkthrough

1. **Clone mission-control** — Clone this repo and open it in Claude Code.

2. **Set up the projects registry** — Run `/init-mission-control` (or manually copy `projects.md.template` → `projects.md` and fill in your project details). This creates the central registry that all skills read from.

3. **Initialize your project** — Run `/init-project` and select your project. This creates `.flight-ops/` in your target project with artifact configuration, methodology reference, and crew definitions.

4. **Review phase files** — Check the files in `{project}/.flight-ops/phases/`. These define the crew composition (roles, models, prompts) for each phase. Customize them to your needs.

5. **Create a mission** — Run `/mission`. This interviews you about desired outcomes and creates a mission artifact in your target project.

6. **Design a flight** — Run `/flight` to break the mission into a technical specification with pre/in/post-flight checklists.

7. **Execute** — Run `/agentic-workflow` to drive multi-agent implementation. This orchestrates design, implement, review, and commit cycles across legs.

8. **Debrief** — Run `/flight-debrief` and `/mission-debrief` after completion to capture lessons learned.

## Documentation

1. **[Overview](docs/overview.md)** — Philosophy and principles behind Flight Control
2. **[Roles](docs/roles.md)** — Crew and Mission Control organizational structure
3. **[Missions](docs/missions.md)** — Writing outcome-driven mission statements
4. **[Flights](docs/flights.md)** — Creating technical specifications with pre/post checklists
5. **[Flight Logs](docs/flight-logs.md)** — Recording execution progress and decisions
6. **[Legs](docs/legs.md)** — Structuring AI-optimized implementation steps
7. **[Workflow](docs/workflow.md)** — End-to-end flow from mission to completion

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
- **Flights**: `planning` → `ready` → `in-flight` → `landed` (or `diverted`)
- **Legs**: `queued` → `in-progress` → `review` → `completed` (or `blocked`)

### Roles

Flight Control scales from solo developers to full teams:

**Solo** — One person fills all roles, using AI as their crew. The methodology provides structure and continuity across sessions.

**Team** — Roles split across people:
- **Crew** executes flights (Commander + Flight Engineer, 1:1 pairing)
- **Mission Control** oversees operations (Flight Director, Ops Director, Technical Architects)

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
```

How you store these artifacts depends on your project's needs. Flight Control supports multiple artifact systems:

- **Markdown files** — Version-controlled documentation in your repository
- **Issue trackers** — Jira, Linear, GitHub Issues with linked relationships
- **Hybrid** — Missions in markdown, flights/legs as tickets

Each project configures its artifact system during initialization. The methodology and Claude Code skills adapt to your choice.

## Claude Code Skills

Flight Control includes Claude Code skills for interactive planning:

| Skill | Purpose |
|-------|---------|
| `/init-project` | Initialize a project for Flight Control |
| `/mission` | Create outcome-driven missions through research and interview |
| `/flight` | Create technical flight specs from missions |
| `/leg` | Generate implementation guidance for LLM execution |
| `/flight-debrief` | Post-flight analysis for continuous improvement |
| `/agentic-workflow` | Drive multi-agent flight execution |
| `/mission-debrief` | Post-mission retrospective for outcomes assessment |

## Recommended Workflow

Flight Control operates across two Claude sessions: **Mission Control** (planning and orchestration) and **Project** (implementation and review).

### Context Strategy

- **Mission Control**: Long-running session spanning an entire flight—accumulates knowledge across legs
- **Project**: Fresh session per leg—relies on artifacts to carry forward knowledge

Review the next leg's design *before* clearing context, while implementation knowledge is fresh. Implement in a clean context.

### The Cycle

```mermaid
sequenceDiagram
    participant MC as Mission Control
    participant P as Project

    Note over MC,P: ─── Mission Planning ───
    MC->>MC: "Let's create our first mission"
    MC->>MC: Research, interview, define outcomes
    MC->>P: "Mission created,<br/>review for alignment"
    P->>P: Review mission
    P->>P: Make changes to artifacts
    P-->>MC: "Mission updated, validate"
    MC->>MC: Review changes

    alt Changes needed
        MC->>P: "These items need attention"
        P->>P: Review and update
        P-->>MC: "Updated"
    end

    MC->>P: "Mission confirmed"

    Note over MC,P: ─── Flight Planning ───
    MC->>MC: "Let's design the first flight"
    MC->>MC: Create technical spec, checklists
    MC->>P: "Flight created,<br/>review for completeness"
    P->>P: Review flight spec
    P->>P: Make changes to artifacts
    P-->>MC: "Flight updated, validate"
    MC->>MC: Review changes

    alt Changes needed
        MC->>P: "These items need attention"
        P->>P: Review and update
        P-->>MC: "Updated"
    end

    MC->>P: "Flight confirmed"

    Note over MC,P: ─── Leg Cycle (repeats) ───
    Note over MC: Long-running context<br/>(entire flight)

    MC->>MC: "Let's design the next leg"
    MC->>P: "Leg N designed,<br/>review for completeness"

    Note over P: Clear context

    P->>P: Review leg N design
    P->>P: Make changes to artifacts
    P-->>MC: "Leg N updated, validate"

    MC->>MC: Review changes

    alt Changes needed
        MC->>P: "These items need attention"
        P->>P: Review and update
        P-->>MC: "Updated"
    end

    MC->>P: "Leg N confirmed"

    Note over P: Clear context

    P->>P: "Let's implement leg N"
    P->>P: Update flight logs
    P->>P: Propagate: update flight, mission,<br/>claude.md based on changes
    P-->>MC: "Leg N complete"

    MC->>MC: Review all changes

    alt Changes needed
        MC->>P: "These items need attention"
        P->>P: Review and update
        P-->>MC: "Updated"
    end

    MC->>MC: "Let's design the next leg"
    MC->>P: "Leg N+1 designed,<br/>review for completeness"

    P->>P: Review leg N+1 design<br/>(while implementation knowledge fresh)
    P->>P: Make changes to artifacts
    P-->>MC: "Leg N+1 updated, validate"

    Note over P: Clear context

    MC->>MC: Review changes
    MC->>P: "Leg N+1 confirmed"

    Note over P: Clear context

    P->>P: "Let's implement leg N+1"
    P->>P: Propagate

    Note over P: Leg cycle repeats...

    Note over MC,P: When flight lands:<br/>"Let's design the next flight"
```

### Why This Matters

Implementation reveals reality. Without propagating that knowledge back into artifacts:
- The next project session starts with stale assumptions
- Mission Control's long-running context drifts from the code
- Each leg operates on increasingly outdated plans

The discipline of review-before-clear and propagate-before-complete keeps artifacts synchronized with truth.

## License

[AGPL-3.0](LICENSE)
