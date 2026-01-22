# Flight Operations

This directory contains reference materials for the [Flight Control](https://github.com/anthropics/flight-control) development methodology.

## Contents

- **FLIGHT_OPERATIONS.md** — Quick reference for implementing missions, flights, and legs
- **ARTIFACTS.md** — Project-specific configuration for how artifacts are stored

## For AI Agents

When working on this project with Flight Control:

1. Read `ARTIFACTS.md` to understand how this project stores missions, flights, and legs
2. Read `FLIGHT_OPERATIONS.md` for the implementation workflow
3. Check the artifact locations defined in `ARTIFACTS.md` for active work
4. Follow the code review gate before marking any leg complete
5. Update flight-log after each leg (location depends on artifact system)

## Sync Behavior

| File | Synced? | Notes |
|------|---------|-------|
| README.md | Yes | Updated via `/init-project` |
| FLIGHT_OPERATIONS.md | Yes | Updated via `/init-project` |
| ARTIFACTS.md | No | Project-specific, customize freely |
