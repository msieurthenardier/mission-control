---
name: leg
description: Generate detailed implementation guidance for LLM execution. Use when creating atomic implementation steps from a flight, generating leg specs, or preparing work for execution. Triggers on "create leg", "new leg", "leg spec", "implementation guide".
---

# Leg Implementation Guidance

Generate detailed implementation guidance for LLM execution.

## Prerequisites

- A flight must exist before creating legs. If no flight context is provided, ask which flight this leg belongs to.
- **Flight Operations reference synced**: Run `/init-project` if this is a new project or if you haven't recently verified the reference is current

## Workflow

### Phase 1: Context Loading

1. **Identify the target project**
   - Read `projects.md` to find the project's path, remote, and description

2. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats
   - This defines where and how missions, flights, and legs are stored

3. **Read the parent flight**
   - Understand the objective being achieved
   - Review design decisions and constraints
   - Note the technical approach defined

4. **Read the flight log in detail** (critical if it exists)

   **This step is essential.** The flight log captures ground truth from actual implementation—what worked, what didn't, and what changed. Skipping or skimming it leads to legs that ignore hard-won learnings.

   Read the full flight log and extract:
   - **Actual outcomes** from completed legs (not just "done" but what specifically happened)
   - **Deviations** from the original plan and why they occurred
   - **Anomalies** discovered during execution that affect future legs
   - **Environment details** (versions, configurations, constraints discovered)
   - **Decisions made** during implementation that weren't in the original flight
   - **Workarounds** for issues encountered (these often affect subsequent legs)

   Pay special attention to:
   - Entries marked as deviations or anomalies
   - Version numbers and tool outputs recorded
   - Warnings or edge cases discovered during prior legs
   - Any "note for future legs" comments

5. **Identify this leg's scope**
   - Which leg from the flight's leg list?
   - What comes before and after this leg?
   - Are there dependencies on other legs?
   - How do prior leg outcomes (from flight log) affect this leg?

6. **Identify environment constraints**
   - Does this leg require a specific execution environment (devcontainer, WSL, cloud)?
   - What user context is required (root, specific user, service account)?
   - What environment variables or shell setup is needed (`source ~/.cargo/env`, `nvm use`, etc.)?
   - Are there commands that must run inside vs outside containers?
   - Document these constraints explicitly in the leg's Context section

### Phase 2: Implementation Analysis

Deep dive into the specific implementation in the **target project**:

1. **Identify exact files to modify**
   - Read existing files that will be changed
   - Understand current code structure
   - Note imports, dependencies, patterns

2. **Understand existing patterns**
   - How is similar functionality implemented?
   - What conventions does the codebase follow?
   - What testing patterns are used?

3. **Determine inputs and outputs**
   - What state exists before this leg?
   - What state must exist after completion?
   - What can the implementing agent assume?

4. **Identify edge cases**
   - What could go wrong?
   - What validation is needed?
   - What error handling is required?

5. **Identify dependent code** (critical for interface changes)
   - Does this leg modify shared interfaces (commands, APIs, types, schemas)?
   - What files consume these interfaces?
   - Will those consumers break or need updates?
   - Should updating consumers be part of this leg or a separate leg?

6. **Identify platform considerations** (for hardware/OS features)
   - Does this leg touch audio, graphics, filesystem, networking, or other OS features?
   - What platform differences might affect implementation?
   - Are there platform-specific dependencies or permissions?
   - Document these in the Platform Considerations section

### Phase 3: Guidance Generation

Create the leg document with this structure:

```markdown
# Leg: {slug}

## Flight Link
[{Flight Title}](../flight.md)

## Objective
Single sentence: what this leg accomplishes.

## Context
Information needed to understand this task:
- Relevant design decisions from the flight
- How this fits into the broader technical approach
- Constraints that affect implementation

**From the flight log** (include if prior legs exist):
- Key learnings from completed legs that affect this work
- Deviations or anomalies that change assumptions
- Environment specifics discovered (versions, configurations)
- Workarounds established that this leg should follow

## Inputs
What exists before this leg runs:
- Files that must exist
- State that must be true
- Dependencies that must be available

## Outputs
What exists after this leg completes:
- Files created or modified
- State changes
- Side effects

## Acceptance Criteria
- [ ] Criterion 1 (specific, observable)
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Guidance

Step-by-step guidance for implementation:

1. **{First step}**
   - Details about what to do
   - Code example if helpful:
   ```{language}
   // example code
   ```

2. **{Second step}**
   - Details

3. **{Third step}**
   - Details

## Edge Cases

- **{Edge case 1}**: How to handle
- **{Edge case 2}**: How to handle

## Files Affected

- `path/to/file.ext` - {What changes}
- `path/to/test.ext` - {What to test}

## Dependent Code (if modifying shared interfaces)

If this leg adds, removes, or changes shared interfaces (API endpoints, Tauri commands, exported types, database schemas), list consumers that may need updates:

- `path/to/consumer.ext` - {How it uses the interface, what needs updating}

## Workarounds (if implementing non-ideal solutions)

If this leg implements a workaround rather than the ideal solution, document it explicitly:

- **{Workaround name}**: {What it does}
  - **Reason**: {Why the ideal solution wasn't feasible}
  - **Removal condition**: {When/how this should be replaced}

## Platform Considerations (if touching hardware or OS features)

For legs involving hardware, filesystem, networking, or other platform-specific features:

- **Linux**: {e.g., package dependencies, permissions, systemd integration}
- **macOS**: {e.g., code signing, Gatekeeper, Keychain access, notarization}
- **Windows/WSL**: {e.g., path separators, line endings, native vs WSL execution}
```

**Output location**: Defined in `.flight-ops/ARTIFACTS.md`.

## Guidelines

### Writing Effective Objectives

State exactly what the leg accomplishes:

**Weak**:
> Set up the database stuff

**Strong**:
> Create the User model with email, password_hash, and timestamp fields in the Prisma schema

### Acceptance Criteria

Criteria must be:
- **Binary**: Either met or not met
- **Observable**: Can be verified by inspection or test
- **Complete**: Nothing else needed for "done"

**Weak criteria**:
- "Code is clean" (subjective)
- "Error handling is good" (vague)

**Strong criteria**:
- "User model exists in `prisma/schema.prisma`"
- "All async operations have try/catch blocks"
- "`npm test` passes with no failures"

### Implementation Guidance

Be explicit, not implicit:

**Implicit** (requires inference):
> Add validation to the email field

**Explicit** (no inference needed):
> Add email validation using the `validator` library's `isEmail` function. Return HTTP 400 with `{ "error": "Invalid email format" }` on validation failure.

### Code Examples

Provide examples when:
- The codebase has specific patterns to follow
- There are multiple valid approaches
- The implementation isn't obvious from context

### Leg Sizing

A well-sized leg:
- Takes minutes to a few hours
- Is atomic (can be completed independently)
- Has clear, verifiable acceptance criteria
- Produces a working increment

**Too small**: Single-line change with no meaningful criteria
**Too large**: Would benefit from intermediate checkpoints

### Documenting Workarounds

When a leg implements a workaround (not the ideal solution), document it explicitly:
- **What**: Describe the workaround clearly
- **Why**: Explain why the ideal solution wasn't feasible (time, complexity, dependencies)
- **When to remove**: Specify the condition that would allow replacing it with the proper solution

This prevents technical debt from becoming invisible. Future legs can reference workarounds and either build on them intentionally or plan their removal.

### Immutability

Once a leg is `in-progress`:
- Do NOT modify the leg document
- If requirements change, mark the leg `blocked`
- Create a new leg with updated requirements
- Reference the old leg for context

## Output

Create the leg artifact in the **target project** using the location and format defined in `.flight-ops/ARTIFACTS.md`.
