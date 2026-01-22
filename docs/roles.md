# Roles

Flight Control defines two organizational layers: the **Crew** who execute flights, and **Mission Control** who oversee operations and provide support.

## Overview

```
                          MISSION CONTROL
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Flight Director                                               │
│   (executive authority)                                         │
│         │                                                       │
│         ├── Ops Director (scheduling, briefings, monitoring)    │
│         ├── Mission Liaison (requirements, stakeholders)        │
│         └── Technical Architects & Specialists (guidance)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ supports
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                            CREW                                 │
│                                                                 │
│              Commander ◄──────────► Flight Engineer             │
│            (AI-assisted dev)      (real-time review)            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Crew

The crew executes flights. A crew consists of exactly two people working together in real-time.

### Commander

The Commander writes code via AI assistance (e.g., Claude Code). They have hands on the controls.

**Responsibilities:**
- Driving implementation through AI-assisted development
- Making tactical decisions during leg execution
- Communicating blockers and progress to Mission Control
- Requesting guidance from Technical Architects when needed

**Skills:**
- Proficiency with AI-assisted development tools
- Strong software development fundamentals
- Ability to review and validate AI-generated code
- Clear communication under time pressure

### Flight Engineer

The Flight Engineer works alongside the Commander in real-time, providing continuous support and verification.

**Responsibilities:**
- Real-time code review as the Commander works
- Testing and validation during development
- Researching solutions and gathering context
- Communicating with Mission Control on behalf of the crew
- Performing specific technical tasks as needed
- Unblocking the Commander

**Skills:**
- Strong code review ability
- Testing and QA expertise
- Research and communication skills
- Context-switching between support tasks

### Why 1:1 Pairing?

The Commander and Flight Engineer always work as a 1:1 pair. This solves a critical problem with AI-assisted development: **the code review bottleneck**.

AI tools can generate large amounts of code quickly. Traditional code review—done after the fact—creates:
- Lead time delays (waiting for review)
- Reviewer fatigue (too much code to review effectively)
- Context loss (reviewer wasn't present during decisions)
- Compliance risks (reviews become rubber stamps)

The Flight Engineer reviews in real-time as code is written:
- Catches issues immediately
- Shares context with the Commander
- Keeps development velocity high
- Maintains code quality without delays

### Crew Communication

The crew operates as a unit. Externally, they speak with one voice:
- Flight Engineer typically handles Mission Control communication
- Commander stays focused on implementation
- Either can escalate blockers

## Mission Control

Mission Control oversees all flights, provides support, and maintains organizational alignment.

### Flight Director

The Flight Director has ultimate authority over all missions. This is an executive leadership role (Director, VP, or equivalent).

**Responsibilities:**
- Strategic oversight of all active missions
- Final authority on mission priorities and resource allocation
- Escalation point for cross-mission conflicts
- Accountability for mission outcomes

**Authority:**
- Can abort or redirect any mission
- Approves major scope changes
- Resolves disputes between missions competing for resources

### Ops Director

The Ops Director is the operational hub, keeping flights running smoothly.

**Responsibilities:**
- Monitoring active flights for blockers or delays
- Scheduling crews to flights
- Running mission and flight briefings
- Running flight debriefings and retrospectives
- Coordinating handoffs between crews
- Tracking mission progress and reporting status

**Skills:**
- Operational management
- Scheduling and resource coordination
- Facilitation of meetings and retrospectives
- Status tracking and communication

### Mission Liaison

The Mission Liaison is the bridge between the organization and external stakeholders.

**Responsibilities:**
- Communicating with customers and stakeholders
- Refining and clarifying requirements
- Answering questions during flights (or finding answers)
- Contributing to mission writing and prioritization
- Translating stakeholder needs into mission outcomes

**Skills:**
- Stakeholder management
- Requirements gathering and refinement
- Clear written and verbal communication
- Product sense and prioritization

### Technical Architects & Specialists

Technical experts who provide guidance without being embedded in crews.

**Responsibilities:**
- Architectural guidance during flight planning
- Design decision consultation
- Specialist expertise (security, performance, infrastructure, etc.)
- Technical standards and patterns

**Engagement:**
- Consulted during pre-flight planning
- Available for escalations during flights
- Review architectural decisions in retrospectives

## Role Combinations

In smaller organizations, individuals may hold multiple roles.

### Common Combinations

| Combination | Notes |
|-------------|-------|
| Flight Director + Ops Director | Executive who also handles operations |
| Mission Liaison + Ops Director | Combined product/operations role |
| Technical Architect + Flight Engineer | Senior engineer who reviews and provides architecture |
| Flight Director + Mission Liaison | Executive with product ownership |

### Minimum Viable Organization

The absolute minimum for Flight Control:

```
Flight Director (1) ─── owns outcomes, handles liaison duties
         │
         └── Crew (2) ─── Commander + Flight Engineer
```

This works for small teams but limits throughput to one active flight.

### Scaling Up

As the organization grows:

```
Flight Director (1)
├── Ops Director (1)
├── Mission Liaison (1-2)
├── Technical Architects (1-3)
└── Crews (n)
    ├── Crew A: Commander + Flight Engineer
    ├── Crew B: Commander + Flight Engineer
    └── Crew C: Commander + Flight Engineer
```

Multiple crews enable parallel flights across missions.

## Solo Flights

A "solo flight" is when one person acts as both Commander and Flight Engineer. This is **not ideal** but may be necessary due to scheduling constraints.

### When Solo Flights Happen

- Scheduling crunches
- Urgent hotfixes
- Low-complexity legs
- Resource constraints

### Solo Flight Risks

- No real-time code review
- Increased cognitive load
- Higher risk of defects
- Slower overall velocity (despite feeling faster)

### Mitigating Solo Flight Risks

If a solo flight is unavoidable:
- Keep legs small and focused
- Prioritize test coverage
- Request post-flight review from another engineer
- Document decisions more thoroughly
- Flag the solo status in flight notes

Solo flights should be exceptions, not the norm. The code review problem doesn't disappear—it just gets deferred.

## Role Transitions

People may move between roles over time or within a day.

### Within a Day

- Morning: Flight Engineer on Crew A
- Afternoon: Technical Architect consulting on Crew B's pre-flight

### Career Progression

```
Flight Engineer → Commander → Technical Architect
                           → Ops Director
                           → Mission Liaison
```

Crew experience builds context for Mission Control roles.

## Briefings and Debriefings

Roles come together at key moments:

### Mission Briefing

**Attendees:** Flight Director, Ops Director, Mission Liaison, Technical Architects, Crew leads
**Purpose:** Align on mission outcomes, success criteria, constraints
**Led by:** Ops Director

### Flight Briefing (Pre-Flight)

**Attendees:** Crew, relevant Technical Architects, Mission Liaison
**Purpose:** Review flight plan, resolve open questions, confirm readiness
**Led by:** Ops Director

### Flight Debriefing (Post-Flight)

**Attendees:** Crew, Ops Director, relevant stakeholders
**Purpose:** Retrospective, capture learnings, verify completion
**Led by:** Ops Director

### Mission Debriefing

**Attendees:** Flight Director, Ops Director, Mission Liaison, all involved crews
**Purpose:** Review mission outcomes, organizational learnings
**Led by:** Flight Director

## Summary

| Role | Layer | Focus |
|------|-------|-------|
| Commander | Crew | AI-assisted implementation |
| Flight Engineer | Crew | Real-time review and support |
| Flight Director | Mission Control | Executive authority |
| Ops Director | Mission Control | Operations and scheduling |
| Mission Liaison | Mission Control | Stakeholders and requirements |
| Technical Architects | Mission Control | Technical guidance |
