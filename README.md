# Flight Control

An AI-first software development lifecycle methodology using aviation metaphors to bridge human intent and AI execution.

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

Aviation succeeds through layered planning and clear handoffs. Pilots don't improvise routes mid-flight; they follow flight plans while retaining authority to adapt. Similarly, Flight Control separates strategic intent (missions) from tactical execution (legs), with flights serving as the translation layer.

## Quick Start

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

Two organizational layers execute and support flights:

**Crew** (executes flights, always 1:1 pairing):
- **Commander** — Drives implementation via AI-assisted development
- **Flight Engineer** — Real-time code review, testing, research, support

**Mission Control** (oversees operations):
- **Flight Director** — Executive authority over all missions
- **Ops Director** — Scheduling, briefings, monitoring active flights
- **Mission Liaison** — Stakeholder communication, requirements refinement
- **Technical Architects** — Architectural guidance and specialist expertise

## Artifact Organization

The hierarchy nests naturally:

```
Mission
├── Mission Briefing
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
| `/mission` | Create outcome-driven missions through research and interview |
| `/flight` | Create technical flight specs from missions |
| `/leg` | Generate implementation guidance for LLM execution |
| `/flight-debrief` | Post-flight analysis for continuous improvement |
| `/mission-debrief` | Post-mission retrospective for outcomes assessment |

### Skill Workflow

```
/mission
    │
    ├── Research codebase and docs
    ├── Interview for outcomes and constraints
    ├── Draft mission with success criteria
    └── Review and iterate
           │
           ▼
/flight
    │
    ├── Load mission context
    ├── Interrogate relevant code
    ├── Interview for technical approach
    ├── Draft flight spec with legs
    └── Review and iterate
           │
           ▼
/leg
    │
    ├── Load flight context
    ├── Analyze implementation details
    └── Generate detailed leg guidance
```

Skills are adaptive—they ask clarifying questions and can update plans as understanding develops.

## Roadmap

- [ ] Mission/flight/leg templates
- [x] Claude Code skills for flight control workflow
- [ ] MCP server for state management
- [ ] Automated leg generation from flights

## License

[AGPL-3.0](LICENSE)
