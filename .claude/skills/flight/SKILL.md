---
name: flight
description: Create technical flight specifications from missions. Use when breaking down a mission into implementable work, planning technical approach, or creating flight specs. Triggers on "create flight", "new flight", "plan flight", "flight spec".
---

# Flight Specification

Create a technical flight spec from a mission.

## Prerequisites

- A mission must exist before creating a flight. If no mission context is provided, ask which mission this flight supports.
- **Flight Operations reference synced**: Run `/init-project` if this is a new project or if you haven't recently verified the reference is current

## Workflow

### Phase 1: Context Gathering

1. **Identify the target project**
   - Read `projects.md` to find the project's path, remote, and description

2. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats
   - This defines where and how missions, flights, and legs are stored

3. **Read the parent mission**
   - Understand the outcome being pursued
   - Identify which success criteria this flight addresses
   - Note constraints that apply

4. **Check existing flights**
   - What flights already exist for this mission?
   - What's been completed vs. in progress?
   - Are there dependencies on other flights?

### Phase 2: Code Interrogation

Explore the **target project's codebase** to inform the technical approach:

1. **Identify relevant code areas**
   - What existing code relates to this flight?
   - What patterns are already established?
   - What dependencies exist?

2. **Find files likely to be affected**
   - Source files to modify
   - Test files to create/update
   - Configuration changes needed

3. **Understand existing patterns**
   - Code style and conventions
   - Error handling approaches
   - Testing patterns

### Phase 3: Crew Interview

Ask technical questions to resolve the approach:

1. **Technical approach**
   - "Should we extend existing code or create new modules?"
   - "What's the preferred pattern for [specific decision]?"
   - "Are there performance considerations?"

2. **Open questions**
   - Surface any ambiguities in requirements
   - Clarify edge cases
   - Identify unknowns that need resolution

3. **Design decisions**
   - Document choices and rationale
   - Get agreement on trade-offs
   - Note any constraints discovered

4. **Prerequisites verification**
   - "Is [dependency] ready?"
   - "Do we have access to [resource]?"
   - "Has [blocking work] been completed?"

5. **Environment capabilities**
   - "What environment will this run in?" (devcontainer, local, CI, cloud)
   - "Is GUI available for visual verification?"
   - "Are there hardware requirements?" (audio, GPU, specific ports)
   - "What commands need special context?" (docker exec, sudo, specific users)

### Phase 4: Spec Creation

Create the flight document with this structure:

```markdown
# Flight: {Title}

## Mission Link

**Mission**: [{Mission Title}](../mission.md)

**Contributing to criteria**:
- [ ] {Relevant success criterion 1}
- [ ] {Relevant success criterion 2}

---

## Pre-Flight

### Objective
What this flight accomplishes (one paragraph).

### Open Questions
- [ ] Question needing resolution
- [x] Resolved question → see Design Decisions

### Design Decisions

**{Decision Title}**: {Choice made}
- Rationale: Why this choice
- Trade-off: What we're giving up
- Decided by: Who made this call

### Prerequisites
- [ ] {What must be true before execution}

### Pre-Flight Checklist
- [ ] All open questions resolved
- [ ] Design decisions documented
- [ ] Prerequisites verified
- [ ] Environment capabilities confirmed (GUI, audio, network, etc.)
- [ ] Acceptance criteria achievable in target environment
- [ ] Legs defined

---

## In-Flight

### Technical Approach
How the objective will be achieved (numbered steps).

### Checkpoints
- [ ] {Milestone 1}
- [ ] {Milestone 2}

### Adaptation Criteria

**Divert if**:
- {Condition requiring re-planning}

**Acceptable variations**:
- {Minor changes that don't require diversion}

### Legs
- [ ] `{leg-slug}` - {Brief description}
- [ ] `{leg-slug}` - {Brief description}

---

## Post-Flight

### Completion Checklist
- [ ] All legs completed
- [ ] Code merged
- [ ] Tests passing
- [ ] Documentation updated

### Verification
How to confirm the flight achieved its objective.

### Retrospective Notes
(Filled after completion)
```

**Output location**: Defined in `.flight-ops/ARTIFACTS.md`.

### Phase 5: Review and Iterate

1. Walk through the spec with the crew
2. Validate technical approach is sound
3. Confirm leg breakdown is appropriate
4. Refine until approved

## Guidelines

### Flight Sizing

A well-sized flight:
- Takes 1-3 days of focused work
- Breaks into 3-8 legs typically
- Has a clear, verifiable objective
- Addresses specific mission criteria

**Too small**: Single leg's worth of work
**Too large**: More than a week of work, vague checkpoints

### Leg Identification

Break flights into legs based on technical boundaries:
- Each leg should be atomic (independently completable)
- Legs should have clear inputs and outputs
- Consider dependencies between legs
- Group related changes together

**For scaffolding/foundation flights**: Always include a final `verify-integration` leg that:
- Confirms all components work together
- Tests end-to-end flows (e.g., frontend calls backend)
- Fixes any integration issues discovered
- Validates the build/deploy process

**For flights that modify shared interfaces**: Include interface changes in the leg list:
- Note which interfaces are added, changed, or removed
- Identify consumers that need updates
- Either update consumers in the same leg or create explicit follow-up legs

### Pre-Flight Rigor

Don't skip pre-flight:
- Open questions MUST be resolved before execution
- Design decisions MUST be documented with rationale
- Prerequisites MUST be verified, not assumed

### Adaptive Planning

- Flights can be modified during the `planning` state
- Once `in-flight`, create diversions rather than editing
- Ask: "Have circumstances changed that affect this flight?"
- New legs can be added if scope grows

## Output

Create the following artifacts in the **target project** using the locations and formats defined in `.flight-ops/ARTIFACTS.md`:

1. **Flight spec** — The flight plan document
2. **Flight log** — Running record for execution (see [Flight Logs](../../../docs/flight-logs.md) for structure)
3. **Legs container** — Where leg artifacts will be created
