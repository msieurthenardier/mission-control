---
name: flight
description: Create technical flight specifications from missions. Use when breaking down a mission into implementable work or planning technical approach.
---

# Flight Specification

Create a technical flight spec from a mission.

## Prerequisites

- A mission must exist before creating a flight
- **Flight Operations reference synced**: Run `/init-project` if needed

## Workflow

### Phase 1: Context Gathering

1. **Identify the target project**
   - Read `projects.md` to find the project's path

2. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats

3. **Read the parent mission**
   - Understand the outcome being pursued
   - Identify which success criteria this flight addresses
   - Note constraints that apply

4. **Check existing flights**
   - What flights already exist for this mission?
   - What's been completed vs. in progress?
   - Are there dependencies on other flights?

### Phase 2: Code Interrogation

Explore the target project's codebase to inform the technical approach:

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
   - Surface ambiguities in requirements
   - Clarify edge cases
   - Identify unknowns

3. **Design decisions**
   - Document choices and rationale
   - Get agreement on trade-offs
   - Note constraints discovered

4. **Prerequisites verification**
   - "Is [dependency] ready?"
   - "Do we have access to [resource]?"

5. **Environment capabilities**
   - "What environment will this run in?"
   - "Is GUI available for visual verification?"
   - "Are there hardware requirements?"

### Phase 4: Spec Creation

Create the flight artifact using the format defined in `.flight-ops/ARTIFACTS.md`.

Also create the flight log artifact (empty, ready for execution notes).

### Phase 5: Iterate

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

**For scaffolding flights**: Include a final `verify-integration` leg

**For interface changes**: Identify consumers that need updates

### Pre-Flight Rigor

- Open questions MUST be resolved before execution
- Design decisions MUST be documented with rationale
- Prerequisites MUST be verified, not assumed

### Adaptive Planning

- Flights can be modified during `planning` state
- Once `in-flight`, create diversions rather than editing
- New legs can be added if scope grows

## Output

Create the following artifacts using locations and formats from `.flight-ops/ARTIFACTS.md`:

1. **Flight spec** — The flight plan
2. **Flight log** — Empty, ready for execution notes
