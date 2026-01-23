---
name: flight-debrief
description: Post-flight analysis for continuous improvement. Use after a flight is completed to capture lessons learned and improve the methodology.
---

# Flight Debrief

Perform comprehensive post-flight analysis for continuous improvement.

## Prerequisites

- A flight must be completed (status `landed` or `diverted`) before debriefing
- **Flight Operations reference synced**: Run `/init-project` if needed

## Workflow

### Phase 1: Context Loading

1. **Identify the target project**
   - Read `projects.md` to find the project's path

2. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats

3. **Load flight documentation**
   - Read the mission for overall context and success criteria
   - Read the flight for objectives, design decisions, and checkpoints
   - Read ALL legs to understand the planned implementation
   - Read the complete flight log for ground truth on what happened

4. **Load project context**
   - Read the target project's `README.md` and `CLAUDE.md`
   - Identify key implementation files from leg outputs and flight log

5. **Examine actual implementation**
   - Read files created or modified during the flight
   - Compare intended vs actual implementation
   - Note deviations, workarounds, or unexpected discoveries

### Phase 2: Deep Analysis

Analyze the flight across multiple dimensions:

#### Outcome Analysis
- Did the flight achieve its objective?
- Which mission success criteria did this flight advance?
- Were all checkpoints met?
- What value was delivered?

#### Process Analysis
- How accurate were the leg specifications?
- Were there gaps requiring improvisation?
- Did the leg sequence make sense?
- Were legs appropriately sized?
- Did acceptance criteria prove verifiable?

#### Technical Analysis
- What technical decisions were made during flight that weren't planned?
- Were there architectural surprises?
- What technical debt was introduced?
- Does implementation align with project conventions?

#### Deviation Analysis
- What deviations occurred and why?
- Were deviations captured in the flight log?
- Should any deviations become standard practice?

#### Knowledge Capture
- What was learned that should be documented?
- Are there reusable patterns that emerged?
- Are README or CLAUDE.md updates needed?

### Phase 3: Skill Effectiveness Analysis

Evaluate whether the mission-control skills could be improved:

#### Mission Skill
- Did the mission provide adequate context?
- Were success criteria clear and measurable?

#### Flight Skill
- Did the flight structure support execution?
- Were design decisions adequately captured?
- Was the leg breakdown appropriate?

#### Leg Skill
- Did legs provide sufficient implementation guidance?
- Were acceptance criteria verifiable?
- Were edge cases adequately identified?

### Phase 4: Generate Debrief

Create the flight debrief artifact using the format defined in `.flight-ops/ARTIFACTS.md`.

## Guidelines

### Thoroughness Over Speed
- Read files completely, not just skim
- Consider root causes, not just symptoms
- Think about systemic improvements

### Be Specific and Actionable
Avoid vague recommendations. Instead of "improve documentation," say:
- "Add a 'Devcontainer Commands' section to CLAUDE.md documenting the docker exec workflow"

### Distinguish Severity
- **Critical**: Would have prevented significant rework or failure
- **Important**: Would have meaningfully improved efficiency
- **Minor**: Nice-to-have improvements

### Credit What Worked
Identify effective patterns that should be reinforced or codified.

### Consider the Meta-Level
- Did the mission/flight/leg hierarchy work?
- Were the right artifacts being created?
- Is there friction that could be eliminated?

## Output

Create the debrief artifact using the location and format defined in `.flight-ops/ARTIFACTS.md`.

After creating the debrief, summarize the top 3-5 most impactful recommendations.
