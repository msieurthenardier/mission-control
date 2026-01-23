---
name: mission-debrief
description: Post-mission retrospective for outcomes assessment and methodology improvement. Use after a mission completes or aborts to capture overall lessons learned.
---

# Mission Debrief

Perform comprehensive post-mission retrospective and methodology assessment.

## Prerequisites

- Project must be initialized with `/init-project` (`.flight-ops/ARTIFACTS.md` must exist)
- A mission must be completed (status `completed` or `aborted`) before debriefing

## Workflow

### Phase 1: Context Loading

1. **Identify the target project**
   - Read `projects.md` to find the project's path

2. **Verify project is initialized**
   - Check if `{target-project}/.flight-ops/ARTIFACTS.md` exists
   - **If missing**: STOP and tell the user to run `/init-project` first
   - Do not proceed without the artifact configuration

3. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats

4. **Load mission documentation**
   - Read the mission for original outcome, success criteria, and constraints
   - Read ALL flight documents for objectives and results
   - Read ALL flight debriefs for per-flight lessons learned
   - Read flight logs for execution details

5. **Load project context**
   - Read the target project's `README.md` and `CLAUDE.md`
   - Understand what was built during this mission

### Phase 2: Outcome Assessment

#### Success Criteria Evaluation
For each success criterion:
- Was it met? Partially met? Not met?
- What evidence supports this assessment?
- If not met, what blocked it?

#### Overall Outcome
- Did the mission achieve its stated outcome?
- Was the outcome still the right goal by the end?
- What value was delivered to stakeholders?

### Phase 3: Flight Analysis

#### Flight Summary
For each flight:
- Status (landed/diverted)
- Key accomplishments
- Major challenges

#### Flight Patterns
- Which flights went smoothly? Why?
- Which flights struggled? Why?
- Were there common issues across flights?

### Phase 4: Process Analysis

#### Planning Effectiveness
- Was the initial flight plan accurate?
- How many flights were added/removed/changed?
- Were estimates reasonable?

#### Execution Patterns
- What worked well in execution?
- What friction points emerged?
- Were the right artifacts being created?

#### Methodology Assessment
- Did the mission/flight/leg hierarchy work for this project?
- Were briefings and debriefs valuable?
- What would you change about the process?

### Phase 5: Knowledge Capture

#### Lessons Learned
- Technical lessons (architecture, patterns, tools)
- Process lessons (planning, execution, communication)
- Domain lessons (business logic, requirements)

#### Reusable Patterns
- What patterns emerged that could be templated?
- What conventions should be documented?

#### Documentation Updates
- Does CLAUDE.md need updates?
- Does README need updates?
- Are there new runbooks or guides needed?

### Phase 6: Generate Debrief

Create the mission debrief artifact using the format defined in `.flight-ops/ARTIFACTS.md`.

## Guidelines

### Holistic View
Look at the mission as a whole, not just individual flights. Identify patterns and systemic issues.

### Stakeholder Perspective
Frame outcomes in terms stakeholders care about. Did we deliver what was promised?

### Honest Assessment
Be candid about what didn't work. The debrief is for learning, not for blame.

### Actionable Insights
Every lesson should have a "so what?" — how should future missions be different?

### Methodology Feedback
This is the best time to identify improvements to Flight Control itself.

## Output

Create the debrief artifact using the location and format defined in `.flight-ops/ARTIFACTS.md`.

After creating the debrief, summarize:
1. Overall mission outcome assessment
2. Top 3 things that went well
3. Top 3 things to improve
4. Recommended methodology changes
