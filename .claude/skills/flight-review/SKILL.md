---
name: flight-review
description: Post-flight analysis for continuous improvement. Use after a flight is completed to capture lessons learned and improve the methodology.
---

# Flight Review

Perform comprehensive post-flight analysis for continuous improvement.

## Prerequisites

- A flight must be completed (status `landed` or `diverted`) before review. If no flight is specified, ask which flight to review.
- **Flight Operations reference synced**: Run `/init-project` if this is a new project or if you haven't recently verified the reference is current

## Workflow

### Phase 1: Context Loading

1. **Identify the target project**
   - Read `projects.md` to find the project's path, remote, and description

2. **Read the artifact configuration**
   - Read `{target-project}/.flight-ops/ARTIFACTS.md` for artifact locations and formats
   - This defines where and how missions, flights, and legs are stored

3. **Load flight documentation**
   - Read the mission document for overall context and success criteria
   - Read the flight document for objectives, design decisions, and checkpoints
   - Read ALL leg documents to understand the planned implementation
   - Read the complete flight log for ground truth on what actually happened

4. **Load project context**
   - Read the target project's `README.md` for project overview
   - Read the target project's `CLAUDE.md` for development conventions
   - Identify key implementation files from leg outputs and flight log

5. **Review actual implementation**
   - Read files created or modified during the flight (from flight log and leg outputs)
   - Compare intended implementation (from legs) vs actual implementation (from code)
   - Note any deviations, workarounds, or unexpected discoveries

### Phase 2: Deep Analysis

Analyze the flight across multiple dimensions:

#### 2.1 Outcome Analysis
- Did the flight achieve its objective?
- Which mission success criteria did this flight advance?
- Were all checkpoints met?
- What value was delivered?

#### 2.2 Process Analysis
- How accurate were the leg specifications? Did they provide sufficient guidance?
- Were there gaps in the legs that required improvisation?
- Did the leg sequence make sense, or would reordering have been better?
- Were legs appropriately sized (too large, too small, just right)?
- Did acceptance criteria prove to be verifiable and complete?

#### 2.3 Technical Analysis
- What technical decisions were made during flight that weren't in the plan?
- Were there any architectural surprises?
- What technical debt was introduced (intentionally or not)?
- Are there code quality issues that should be addressed?
- Does the implementation align with project conventions (from CLAUDE.md)?

#### 2.4 Deviation Analysis
- What deviations from the plan occurred and why?
- Were deviations captured in the flight log?
- Should any deviations become standard practice?
- Were there anomalies that indicate systemic issues?

#### 2.5 Knowledge Capture
- What was learned that should be documented?
- Are there reusable patterns that emerged?
- What tribal knowledge should be made explicit?
- Are README or CLAUDE.md updates needed?

### Phase 3: Skill Effectiveness Analysis

**Critical**: Evaluate whether the mission-control skills (mission, flight, leg) could be improved based on this flight's experience.

Consider for each skill:

#### Mission Skill
- Did the mission document provide adequate context for flight planning?
- Were success criteria clear and measurable?
- Was the scope appropriate?
- What information was missing that would have helped?

#### Flight Skill
- Did the flight structure support effective execution?
- Were design decisions adequately captured?
- Did the technical approach prove sound?
- Were checkpoints useful for tracking progress?
- Was the leg breakdown appropriate?

#### Leg Skill
- Did leg documents provide sufficient implementation guidance?
- Were acceptance criteria verifiable?
- Did the implementation guidance match actual needs?
- Were edge cases adequately identified?
- Was the context section useful?

#### General Skill Improvements
- Are there common patterns that should be templated?
- Are there sections that are consistently unhelpful?
- Should the skill workflows be modified?
- Are there missing skill features that would help?

### Phase 4: Generate Review Document

Create a comprehensive flight review document with:

```markdown
# Flight Review: {Flight Name}

## Flight Summary
- **Mission**: {Mission name with link}
- **Flight**: {Flight name with link}
- **Status**: {landed/diverted}
- **Duration**: {Start date} - {End date}
- **Legs Completed**: {X of Y}

## Outcome Assessment

### Objectives Achieved
{What the flight accomplished}

### Mission Criteria Advanced
{Which success criteria this flight contributed to}

### Checkpoints Status
{Final status of all checkpoints}

## What Went Well
{Specific things that worked effectively}

## What Could Be Improved

### Target Project Improvements
{Recommendations for the project itself}

#### Code Quality
- {Specific issues and recommendations}

#### Documentation
- {README, CLAUDE.md, inline docs improvements}

#### Architecture
- {Structural improvements for future flights}

#### Technical Debt
- {Debt introduced and remediation recommendations}

### Process Improvements
{Recommendations for how the flight was executed}

#### Leg Specification Quality
- {What was missing or unclear in legs}

#### Flight Planning
- {How the flight could have been better planned}

#### Flight Log Usage
- {How logging could be improved}

## Deviations and Lessons Learned

### Significant Deviations
| Deviation | Reason | Should Standardize? |
|-----------|--------|---------------------|
| {deviation} | {why} | {yes/no + rationale} |

### Key Learnings
{Insights that should inform future flights}

## Skill Improvement Recommendations

### Mission Skill (`/mission`)
{Specific improvements to the mission skill template or workflow}

### Flight Skill (`/flight`)
{Specific improvements to the flight skill template or workflow}

### Leg Skill (`/leg`)
{Specific improvements to the leg skill template or workflow}

### New Skill Ideas
{Suggestions for new skills that would have helped}

## Action Items

### Immediate (This Flight)
- [ ] {Action item with owner/location}

### Near-Term (Next Flight)
- [ ] {Action item}

### Methodology (Mission Control)
- [ ] {Skill or process improvement}

## Appendix: Files Reviewed
{List of files examined during this review}
```

**Output location**: Defined in `.flight-ops/ARTIFACTS.md`.

## Guidelines

### Thoroughness Over Speed
This review is about continuous improvement. Take time to:
- Read files completely, not just skim
- Consider root causes, not just symptoms
- Think about systemic improvements, not just local fixes

### Be Specific and Actionable
Avoid vague recommendations like "improve documentation." Instead:
- "Add a 'Devcontainer Commands' section to CLAUDE.md documenting the docker exec workflow discovered in Leg 03"
- "The leg skill should prompt for environment constraints (devcontainer, WSL, etc.) during implementation guidance generation"

### Distinguish Severity
Not all improvements are equal. Categorize by impact:
- **Critical**: Would have prevented significant rework or failure
- **Important**: Would have meaningfully improved efficiency or quality
- **Minor**: Nice-to-have improvements

### Credit What Worked
Don't focus only on problems. Identify effective patterns that should be reinforced or codified.

### Consider the Meta-Level
The most valuable insights often relate to the methodology itself:
- Did the mission/flight/leg hierarchy work for this type of project?
- Were the right artifacts being created?
- Is there friction in the workflow that could be eliminated?

## Output

Create the review artifact in the **target project** using the location and format defined in `.flight-ops/ARTIFACTS.md`.

After creating the review, summarize the top 3-5 most impactful recommendations for immediate attention.
