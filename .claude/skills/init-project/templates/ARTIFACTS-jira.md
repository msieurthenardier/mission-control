# Artifact System: Jira

This project stores Flight Control artifacts as Jira issues.

## Mapping

| Flight Control | Jira Issue Type | Hierarchy |
|----------------|-----------------|-----------|
| Mission | Epic | Parent |
| Flight | Story | Child of Epic |
| Leg | Sub-task | Child of Story |

## Configuration

| Property | Value |
|----------|-------|
| Project Key | `PROJECT` |
| Board | (specify board name or ID) |
| Labels | `flight-control` |

## Artifact Definitions

### Mission → Epic

| Field | Mapping |
|-------|---------|
| Summary | Mission title |
| Description | Mission overview, success criteria, constraints |
| Labels | `flight-control`, `mission` |
| Custom fields | (add project-specific mappings) |

### Flight → Story

| Field | Mapping |
|-------|---------|
| Summary | Flight title |
| Description | Flight objective, pre-flight checklist, post-flight criteria |
| Epic Link | Parent mission epic |
| Labels | `flight-control`, `flight` |
| Acceptance Criteria | Post-flight checklist items |

### Leg → Sub-task

| Field | Mapping |
|-------|---------|
| Summary | Leg title |
| Description | Implementation guidance, acceptance criteria |
| Parent | Flight story |
| Labels | `flight-control`, `leg` |

## State Mapping

### Mission (Epic)

| Flight Control | Jira Status |
|----------------|-------------|
| planning | To Do |
| active | In Progress |
| completed | Done |
| aborted | Cancelled |

### Flight (Story)

| Flight Control | Jira Status |
|----------------|-------------|
| planning | To Do |
| ready | Ready |
| in-flight | In Progress |
| landed | Done |
| diverted | Blocked / Cancelled |

### Leg (Sub-task)

| Flight Control | Jira Status |
|----------------|-------------|
| queued | To Do |
| in-progress | In Progress |
| review | In Review |
| completed | Done |
| blocked | Blocked |

## Supporting Artifacts

### Flight Log

| Property | Value |
|----------|-------|
| Location | Comments on the Flight (Story) |
| Purpose | Running record of decisions, progress, and anomalies during flight execution |
| Format | Timestamped comments, one per significant event |

Example comment:
```
[Flight Log] 2024-01-15 14:30

Completed leg 01-setup-database. Minor deviation: used PostgreSQL 16 instead of 15 due to availability.

Next: Starting leg 02-api-endpoints.
```

### Flight Review

| Property | Value |
|----------|-------|
| Location | Comment on the Mission (Epic) |
| Purpose | Post-flight analysis: what worked, what didn't, lessons learned |
| Created | After flight lands or diverts |
| Label comment | `[Flight Review: {flight-name}]` |

### Mission Review

| Property | Value |
|----------|-------|
| Location | Comment on the Mission (Epic) |
| Purpose | Post-mission retrospective: outcomes achieved, methodology improvements |
| Created | After mission completes or aborts |
| Label comment | `[Mission Review]` |

## Conventions

- **Naming**: Use clear, action-oriented summaries (e.g., "Implement user authentication flow")
- **Linking**: Always link Stories to their parent Epic, Sub-tasks to their parent Story
- **Labels**: Apply `flight-control` label to all artifacts for easy filtering
- **Immutability**: Never modify Sub-tasks once In Progress; create new ones instead
