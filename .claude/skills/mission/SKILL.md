---
name: mission
description: Create outcome-driven missions through research and user interview. Use when starting a new project, feature, or initiative that needs planning. Triggers on "create mission", "new mission", "plan project", "define goals".
---

# Mission Creation

Create a new mission through research and collaborative discovery.

## Prerequisites

- **Flight Operations reference synced**: Run `/init-project` if this is a new project or if you haven't recently verified the reference is current

## Workflow

### Phase 1: Research

Before asking questions, gather context:

1. **Identify the target project**
   - Read `projects.md` to find the project's path, remote, and description
   - If the project isn't listed, ask the user for details

2. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats
   - This defines where and how missions, flights, and legs are stored

3. **Explore the target project's codebase** to understand current state
   - Project structure and architecture
   - Existing patterns and conventions
   - Related functionality that might be affected

4. **Read existing documentation**
   - README and project docs in the target project
   - Any existing missions (check ARTIFACTS.md for location)
   - Technical specs or design documents

5. **Search external sources if needed**
   - API documentation for integrations
   - Library documentation
   - Relevant patterns or best practices

### Phase 2: Interview

Ask about outcomes, not tasks. Focus on:

1. **Desired outcomes**
   - "What does success look like when this is done?"
   - "What problem does this solve for users/stakeholders?"
   - "How will you know this mission succeeded?"

2. **Stakeholders and their needs**
   - "Who benefits from this outcome?"
   - "Are there competing interests to balance?"
   - "Who needs to approve or review?"

3. **Constraints**
   - "What technical constraints exist?"
   - "Are there timeline or resource boundaries?"
   - "What's out of scope?"

4. **Success criteria**
   - "What specific, observable criteria indicate completion?"
   - "How will each criterion be verified?"

5. **Environment requirements**
   - "What development environment will be used?" (devcontainer, local, cloud)
   - "Are there runtime dependencies?" (GUI, audio, network, hardware)
   - "What tooling versions are required?"
   - "Are there verification methods that require specific capabilities?" (visual testing, hardware testing)

### Phase 3: Draft

Create the mission document with this structure:

```markdown
# Mission: {Title}

## Outcome
What success looks like in human terms.

## Context
Why this mission matters now. Background information.

## Success Criteria
- [ ] Criterion 1 (observable, binary)
- [ ] Criterion 2
- [ ] Criterion 3

## Stakeholders
Who cares about this outcome and why.

## Constraints
Non-negotiable boundaries.

## Environment Requirements
Development and execution environment needs:
- Development environment (devcontainer, local toolchain, cloud IDE)
- Runtime requirements (GUI for visual testing, audio hardware, network access)
- Special tooling (Docker, specific CLI versions, hardware access)

## Open Questions
Unknowns that need resolution during execution.

## Flights
Likely flights to execute this mission (typically 5-7):
- Flight 1: {description}
- Flight 2: {description}
- ...
```

**Output location**: Defined in `.flight-ops/ARTIFACTS.md`.

### Phase 4: Review

Present the draft and iterate:

1. Walk through each section with the user
2. Validate success criteria are measurable
3. Confirm flight breakdown makes sense
4. Refine until the user approves

## Guidelines

### Mission Sizing

A well-sized mission:
- Takes days to weeks to complete
- Spawns 5-7 flights typically (adjust based on complexity)
- Represents a meaningful outcome stakeholders recognize
- Has clear success criteria

**Too small**: Can be completed in a single flight
**Too large**: Success criteria are vague or numerous (>10)

### Outcome vs. Activity

Frame missions around results, not tasks:

**Activity-focused** (avoid):
> Implement user authentication

**Outcome-focused** (prefer):
> Users can securely access their personal data without sharing credentials

### Adaptive Planning

- Missions can be updated as understanding develops
- New flights can be added during execution
- Success criteria can be refined (with stakeholder agreement)
- Ask: "Has anything changed since we last discussed this?"

## Output

Create the mission artifact in the **target project** using the location and format defined in `.flight-ops/ARTIFACTS.md`.
