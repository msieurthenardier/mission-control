---
name: mission-debrief
description: Post-mission retrospective for outcomes assessment and methodology improvement. Use after a mission completes or aborts to capture overall lessons learned.
---

# Mission Debrief

Perform comprehensive post-mission retrospective and methodology assessment.

**This skill produces documentation only.** Create and update Flight Control artifacts; never modify source files in the project.

## Prerequisites

- Project must be initialized with `/mission-control:init-project` (`.flightops/ARTIFACTS.md` must exist)
- A mission must have at least one completed or aborted flight before debriefing

## Workflow

### Phase 1: Context Loading

1. **Verify project is initialized**
   - Check if `.flightops/ARTIFACTS.md` exists
   - **If missing**: STOP and tell the user to run `/mission-control:init-project` first
   - Do not proceed without the artifact configuration

2. **Read the artifact configuration**
   - Read `.flightops/ARTIFACTS.md` for how this project handles each artifact — its storage location, format, and any actions the project defines at create and transition time (e.g., transitioning a ticket, posting a notification)

3. **Load mission documentation**
   - Read the mission for original outcome, success criteria, and constraints
   - Read ALL flight documents for objectives and results
   - Read ALL flight debriefs for per-flight lessons learned
   - Read flight logs for execution details

4. **Load project context**
   - Read the project's `README.md` and `CLAUDE.md`
   - Understand what was built during this mission

### Phase 2: Crew Debrief Interviews

Read `.flightops/agent-crews/mission-debrief.md` for crew definitions and prompts (fall back to defaults at `${SKILL_DIR}/../init-project/defaults/agent-crews/mission-debrief.md`).

**Validate structure**: The phase file MUST contain `## Crew`, `## Interaction Protocol`, and `## Prompts` sections with fenced code blocks. If the file exists but is malformed, STOP and tell the user: "Phase file `mission-debrief.md` is missing required sections. Either fix it manually or re-run `/mission-control:init-project` to reset to defaults."

#### Architect Interview
1. **Spawn an Architect agent** in the project context (Task tool, `subagent_type: "general-purpose"`)
   - Provide the "Debrief Interview" prompt from the mission-debrief phase file's Prompts section
   - The Architect reviews architectural evolution across all flights, pattern consistency, and structural health
   - The Architect provides structured debrief input

#### Human Interview
Interview the crew to capture qualitative insights that documents alone cannot reveal.

##### Flight Log Clarifications
Surface specific observations from flight logs and ask for context:
- Anomalies or deviations noted in logs — what caused them?
- Decisions made during execution — what drove those choices?
- Blockers or delays — were these predictable in hindsight?
- Workarounds implemented — should these become standard practice?

##### Mission Control Experience
For the human(s) who served as mission control:
- "What was your experience coordinating this mission?"
- "Were there moments of confusion or uncertainty about status?"
- "Did the flight/leg structure help or hinder your oversight?"
- "What information was missing when you needed it?"

##### Project-Specific Feedback
- "What surprised you most during this mission?"
- "What would you do differently if starting over?"
- "Are there project-specific conventions that should be documented?"
- "Did any tools, libraries, or patterns prove particularly valuable or problematic?"

##### Agentic Orchestration Feedback (if applicable)
If the mission used automated orchestration (LLM agents executing legs):
- "How well did handoffs between agents work?"
- "Were there failures in agent coordination or context transfer?"
- "Did agents make decisions that required human correction?"
- "What guardrails or checkpoints would have helped?"
- "Was the level of autonomy appropriate for the tasks?"

**Note**: Adapt questions based on what the flight logs and artifacts reveal. Surface specific examples rather than asking in the abstract.

### Phase 3: Outcome Assessment (synthesize Architect + human input)

#### Success Criteria Evaluation
For each success criterion:
- Was it met? Partially met? Not met?
- What evidence supports this assessment?
- If not met, what blocked it?

#### Overall Outcome
- Did the mission achieve its stated outcome?
- Was the outcome still the right goal by the end?
- What value was delivered to stakeholders?

### Phase 4: Flight Analysis

#### Flight Summary
For each flight:
- Status (landed/completed/aborted)
- Key accomplishments
- Major challenges

#### Flight Patterns
- Which flights went smoothly? Why?
- Which flights struggled? Why?
- Were there common issues across flights?

### Phase 5: Process Analysis

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

### Phase 6: Knowledge Capture

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

### Phase 7: Triage Methodology Findings

Do this **before** persisting the debrief, so the artifact is complete when it is written and any create-time handling the project defines fires against finished content.

The Methodology Feedback content is about Flight Control itself, not this project. Sort each finding into one of three destinations:

| Destination | When |
|-------------|------|
| **Local fix** | It is friction in this project's own `ARTIFACTS.md` or crew files, which are the project's to customize |
| **Local lesson** | It is real but does not reproduce from the methodology alone, or it cost nothing observable |
| **Methodology observation** | It reproduces from the methodology alone *and* cost something observable — rework, a re-run, a wrong artifact, a missed gate |

Preference without a cost is a local lesson, not a methodology observation. Say so rather than dressing it up.

For each methodology observation, record what the methodology did, what was expected, what it cost, the skill and phase, the plugin version in use, and the **recurrence count** across this mission's flights — pulled from the flight debriefs already read in Phase 1. This is the only point where that count exists.

**This phase records; it does not report.** Nothing here is sent anywhere. A single mission is too small a sample to tell a methodology defect from an awkward stretch, and reporting at mission cadence is what floods a tracker with events. The operator runs `/mission-control:service-report` when *they* choose — typically after several missions — and it sweeps every debrief in the project looking for observations that turned out to be patterns. What Phase 7 owes that sweep is a well-recorded observation, not a decision.

### Phase 8: Generate Debrief

Persist the mission debrief artifact following the conventions `.flightops/ARTIFACTS.md` defines for it, then perform any create-time handling it defines for that artifact (e.g., opening a ticket, posting a notification; default: none).

### Phase 9: Mission Status Transition

If the mission is not already marked as `completed` or `aborted`, update the mission artifact's status to `completed`, and perform any transition-time handling the project's `.flightops/ARTIFACTS.md` defines for that transition (default: none).

## Guidelines

### Holistic View
Look at the mission as a whole, not just individual flights. Identify patterns and systemic issues.

### Stakeholder Perspective
Frame outcomes in terms stakeholders care about. Did we deliver what was promised?

### Honest Assessment
Be candid about what didn't work. The debrief is for learning, not for blame.

### Actionable Insights
Every lesson should have a "so what?" — how should future missions be different?

When a mission-level insight identifies a behavior that should be pinned as a regression gate (especially needing real-environment observation), recommend authoring a **behavior test** spec. See `${SKILL_DIR}/../behavior-test/AUTHORING.md`. The spec gets written during the next mission's planning; the test runs via `/mission-control:behavior-test {slug}`.

### Methodology Feedback
This is the best time to identify improvements to Flight Control itself, and the only point where a finding can be weighed against a full mission of flights rather than one afternoon.

Record observations well; do not adjudicate them. Distinguish three destinations — a change to this project's `ARTIFACTS.md` or crew files (project-owned, fix it locally), a lesson for how this team runs missions, and an observation about the methodology itself (Phase 7). Whether a methodology observation is a real defect is a question about patterns across missions, which no single debrief can answer.

### Interview Integration
Weave interview insights throughout the debrief, not as a separate section. Crew perspectives should inform:
- Why certain outcomes were achieved or missed
- Root causes behind process friction
- Context that flight logs alone cannot capture
- Recommendations that reflect lived experience, not just document analysis

## Output

Deliverable: the debrief artifact, persisted per the conventions `.flightops/ARTIFACTS.md` defines for it.

After creating the debrief, summarize:
1. Overall mission outcome assessment
2. Top 3 things that went well
3. Top 3 things to improve
4. Recommended methodology changes
