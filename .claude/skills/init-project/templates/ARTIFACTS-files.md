# Artifact System: Filesystem

This project stores Flight Control artifacts as markdown files in the repository.

## Structure

```
{project}/
└── missions/
    └── {mission-slug}/
        ├── mission.md
        ├── mission-review.md
        └── flights/
            └── {NN}-{flight-slug}/
                ├── flight.md
                ├── flight-log.md
                ├── flight-review.md
                └── legs/
                    └── {NN}-{leg-slug}.md
```

## Artifact Definitions

### Mission

| Property | Value |
|----------|-------|
| Location | `missions/{slug}/mission.md` |
| Format | Markdown |
| Naming | Kebab-case slug derived from mission title |

### Flight

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{NN}-{slug}/flight.md` |
| Format | Markdown |
| Naming | Two-digit sequence number + kebab-case slug |

### Leg

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/legs/{NN}-{slug}.md` |
| Format | Markdown |
| Naming | Two-digit sequence number + kebab-case slug |

## Supporting Artifacts

### Flight Log

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/flight-log.md` |
| Purpose | Running record of decisions, progress, and anomalies during flight execution |
| Update pattern | Append-only during execution |

### Flight Review

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/flights/{flight}/flight-review.md` |
| Purpose | Post-flight analysis: what worked, what didn't, lessons learned |
| Created | After flight lands or diverts |

### Mission Review

| Property | Value |
|----------|-------|
| Location | `missions/{mission}/mission-review.md` |
| Purpose | Post-mission retrospective: outcomes achieved, methodology improvements |
| Created | After mission completes or aborts |

## Conventions

- **Sequence numbers**: Flights and legs use `01`, `02`, etc. for ordering
- **Slugs**: Lowercase, kebab-case, derived from title (e.g., "User Authentication" → `user-authentication`)
- **Flight log**: Single file per flight, append-only during execution
- **Immutability**: Never modify legs once in-progress; create new ones instead

## State Tracking

States are tracked in the frontmatter or status section of each artifact:

- **Mission**: `status: planning | active | completed | aborted`
- **Flight**: `status: planning | ready | in-flight | landed | diverted`
- **Leg**: `status: queued | in-progress | review | completed | blocked`
