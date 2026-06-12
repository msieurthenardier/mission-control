# Flight Operations Quick Reference

> For full methodology docs, see [mission-control](https://github.com/msieurthenardier/mission-control)

## Before You Start

**Read these files in order:**
1. `.flightops/ARTIFACTS.md` — Where and how artifacts are stored (project-specific)
2. The **flight log** for your active flight — Ground truth for what happened
3. The **leg artifact** you're implementing — Your acceptance criteria

---

## Project Crew & Phases

Each phase of the Flight Control workflow has a crew definition in `.flightops/agent-crews/`:

| Crew | Purpose |
|------|---------|
| `mission-design.md` | Crew for `/mission` (e.g., Architect validates viability) |
| `flight-design.md` | Crew for `/flight` (e.g., Architect reviews spec) |
| `leg-execution.md` | Crew for `/agentic-workflow` (e.g., Developer + Reviewer) |
| `flight-debrief.md` | Crew for `/flight-debrief` (e.g., Developer provides perspective) |
| `mission-debrief.md` | Crew for `/mission-debrief` (e.g., Architect provides perspective) |

Crew files define: roles, models, interaction protocols, prompts, and signals. Customize these to change your project's agent configuration.

---

## Multi-Agent Workflow

Legs must be implemented by a **separate Developer instance** and reviewed by a **separate Reviewer instance** (or whatever crew is defined in `leg-execution.md`). Mission Control designs legs and orchestrates — it does NOT implement code directly.

The Reviewer has no knowledge of the Developer's reasoning — only the resulting changes. This separation provides objective code review. Use the `/agentic-workflow` skill in mission-control to drive this cycle.

---

## ⚠️ Leg Completion Checklist (MANDATORY)

**You MUST complete ALL of these before emitting `[COMPLETE:leg]`:**

| Step | Action |
|------|--------|
| 1 | All acceptance criteria verified |
| 2 | Tests passing |
| 3 | **Update flight log** — Add leg progress entry (see below) |
| 4 | **Mark leg completed** — Update leg status to `completed` |
| 5 | **Update flight** — Check off the leg in flight artifact |
| 6 | **Commit/save with all artifact updates** |

**Flight log entry MUST include:**
- Leg status, started date, completed date
- Changes Made (what was implemented)
- Verification (how acceptance criteria were confirmed)
- Any decisions, deviations, or anomalies

Refer to `.flightops/ARTIFACTS.md` for exact locations and formats.

---

## Workflow Signals

Emit at the end of your response, on its own line:

| Signal | When |
|--------|------|
| `[HANDOFF:review-needed]` | Artifact changes ready for validation |
| `[HANDOFF:confirmed]` | Review complete, no issues |
| `[BLOCKED:reason]` | Cannot proceed |
| `[COMPLETE:leg]` | Leg done AND checklist complete |

---

## Implementing a Leg

### Pre-Implementation
1. Read mission, flight, and leg artifacts
2. Read flight log for context from prior legs
3. Verify leg accuracy against existing code
4. **Update leg status** to `in-flight`
5. Present summary and get approval before proceeding

### Implementation
5. Implement to acceptance criteria
6. Run tests with a timeout — use the test runner's timeout flag (e.g., `--timeout`,
   `--test-timeout`, `-timeout`) so hanging tests fail fast instead of stalling.
   If a test hangs, kill it, isolate the hanging test, and fix the root cause before
   continuing. Log hanging tests and their resolution in the flight log.
7. Run code review, fix Critical/Major issues
8. Re-review until clean

### Post-Implementation
9. Propagate changes (project docs, flight artifacts if scope changed)
10. **Complete the Leg Completion Checklist above**
11. Signal `[COMPLETE:leg]`

---

## Just-in-Time Planning

Flights and legs are created one at a time, not upfront.

| Reviewing... | Should exist | Should NOT exist yet |
|--------------|--------------|----------------------|
| Mission | Mission artifact | Flight artifacts (only listed) |
| Flight | Flight artifact | Leg artifacts (only listed) |
| Leg | Leg artifact | Ready to implement |

Listed flights/legs are **tentative suggestions** that evolve based on discoveries.

---

## Reviewing Artifacts

When reviewing a mission, flight, or leg:

1. Read the artifact thoroughly
2. Validate against project goals and existing code
3. Check for ambiguities or missing details
4. Make changes directly if needed
5. Describe any changes made
6. Signal `[HANDOFF:confirmed]` if no issues, or describe changes for validation

---

## Code Review Gate

```
Implement → Test → Review → Fix → Re-review → Complete
```

| Severity | Action |
|----------|--------|
| Critical | Must fix |
| Major | Must fix |
| Minor | Fix if safe, else defer |

Deferred issues go in the flight log.

---

## ⚠️ Flight Completion Checklist (MANDATORY)

**When you complete the FINAL leg of a flight, also complete these steps:**

| Step | Action |
|------|--------|
| 1 | Complete all items in the Leg Completion Checklist above |
| 2 | **Update flight log** — Add flight completion entry with summary |
| 3 | **Update flight status** — Set `**Status**: landed` in flight.md |
| 4 | **Update mission** — Check off this flight in mission.md |
| 5 | **Verify all legs** — Confirm all legs show `completed` status |
| 6 | **Update project docs** — Ensure CLAUDE.md, README, and other docs reflect any new commands, endpoints, configuration, or APIs introduced during the flight |
| 7 | Signal `[COMPLETE:leg]` (the orchestrator will trigger Phase 4) |

The orchestrator will then:
- Mark the PR ready for human review

The flight debrief is a separate step run via `/flight-debrief`, which transitions the flight from `landed` to `completed`.

---

## Database Schema Changes

When a flight modifies database schemas:

1. **Include migration steps in the leg** — schema changes need explicit CREATE/ALTER statements or migration commands
2. **Verify migrations run** — acceptance criteria must include confirming the migration executed successfully against the live database
3. **Update SCHEMA docs** — if the project maintains a SCHEMA reference, update it in the same leg that creates the migration
4. **Test against real DB** — unit tests with mocks are not sufficient for schema changes; verify against the actual database

A table defined in SCHEMA but never created via migration is a gap — treat schema documentation and migration execution as a single atomic operation.

---

## Behavior Tests

When verification needs **real-environment observation** that unit/integration tests can't provide — testing the running app's UI through a browser, hitting a real API, watching multi-component interactions across UI + DB + queue — author a **behavior test** spec inline during flight or leg planning.

A behavior test is a Zephyr-style two-column **Action | Expected Result** table (human-readable, human-performable) that runs via two live AI agents using the **Witnessed** pattern: an Executor performs each step's Actions; an independent Validator judges each step's Expected Results. The two roles stay alive across the entire test; the orchestrator drives the step cursor. Every action is judged by an agent that didn't perform it — that separation forces a colder verdict than self-judging.

Key concepts:
- **Observable** — a measurable property of the system the test cares about (toggle state, response code, file contents, log line). Borrowed from physics.
- **Apparatus** — the tool that measures the observable (browser MCP, curl, Read tool). The Executor scans available apparatus at run start and matches them against the spec's Observables Required list.
- **Testability discipline**: every Expected Result must reference an observable. If you can't write a measurable Expected Result, the system isn't observable at this layer — find a coarser surface or wire instrumentation.

Where things live:
- **Spec format**: `ARTIFACTS.md`'s "Behavior Test — Spec" section is authoritative.
- **Spec files**: `tests/behavior/{slug}.md` (or wherever ARTIFACTS.md configures).
- **Run logs**: `tests/behavior/{slug}/runs/{ts}.md` (committed). Evidence lives at an ephemeral path outside the project tree (`/tmp/behavior-tests/...`), never committed.
- **Crew (Executor + Validator) prompts**: `.flightops/agent-crews/behavior-tests-execution.md` (project-modifiable scaffolding shipped by `/init-project`).

Workflow:
1. During flight or leg planning, identify a verification need that warrants a behavior test (e.g., "the new toggle must persist across page reload AND reach the backend AND survive a process restart").
2. Author the spec inline using the format in ARTIFACTS.md. Write it to the configured behavior-test directory.
3. Reference the spec slug in the parent artifact's acceptance criteria — e.g., the leg says "Run `/behavior-test <slug>` to verify acceptance."
4. The operator (or the agentic-workflow at HAT time) invokes `/behavior-test <slug>` to execute. The skill spawns the live Executor + Validator crew, drives the step loop, and writes a run log with verdict + evidence.

When NOT to use a behavior test:
- Pure logic / data transforms → unit tests.
- Strict equality on fixtures → unit / integration tests.
- One-shot verification you'll never re-check → debrief note.
- A single deterministic script can verify it → Playwright / pytest.

The behavior-test format is heavyweight (two live agents, evidence directory, run logs); use it for tests where the cost is justified by the value of real-environment observation.

---

## Key Principles

1. **Flight log is ground truth** — Read it first, update it always
2. **Never modify in-flight legs** — Create new ones instead
3. **Binary acceptance criteria** — Met or not met
4. **Log everything** — Decisions, deviations, anomalies
5. **Signal clearly** — End of response, own line
