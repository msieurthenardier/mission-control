---
name: behavior-test
description: Run a behavior test — spawn two live agents (an Executor that performs each step's actions and a Validator that judges each step's expected results), drive them through the spec's step table communicating mid-test so failures surface immediately, then write a run log with evidence. Tests are specs that follow the Witnessed pattern: every action is judged by an independent agent. Verifies system properties through observables (UI state, HTTP responses, shell output, filesystem state) measured via whichever apparatus (MCP, tool) is registered. Invocation: `/behavior-test <slug>` to run a test by slug. Specs are authored inline during flight/leg/mission planning — see `AUTHORING.md` sibling file for the authoring guide. Spec format lives in the target project's `.flightops/ARTIFACTS.md`.
---

# Behavior Test — Run

This skill **runs** behavior tests. Specs are authored inline during planning conversations (flight, leg, mission, debrief, maintenance) — see [`AUTHORING.md`](./AUTHORING.md) for the authoring guide, which planning skills consult on demand. This skill is purely about execution.

## Concept (brief)

A behavior test is a structured acceptance test for AI-driven systems that needs verification against the real world. The spec is a two-column **Action | Expected Result** table (Zephyr-style) — human-readable, human-performable. The skill runs it with two live agents:

- **Executor** — performs each step's Actions when sent one. Reports raw observed state. Makes no judgments.
- **Validator** — judges each step's Expected Results against the Executor's raw state. Renders PASS / FAIL / INCONCLUSIVE per step.

Both agents stay alive across the entire test via SendMessage continuation. The Orchestrator (you, loading this skill) drives the step cursor.

The verification model is called the **Witnessed** pattern: every action is judged by an independent agent. The agent that did the work is never the same agent that decides whether the work was correct.

For the conceptual background (observable + apparatus, testability discipline, Witnessed pattern origin), see `AUTHORING.md`.

## When This Skill Runs

- The operator says "run the X behavior test" or `/behavior-test <slug>`.
- A flight has reached a HAT-style leg whose acceptance criterion is a behavior-test spec.
- CI / scheduled execution needs the test for a regression gate (future — not yet implemented in this skill).

## Prerequisites

- The target project must be initialized with `/init-project` (`.flightops/ARTIFACTS.md` must exist).
- A behavior-test spec must exist at the project's configured behavior-test directory (default `tests/behavior/<slug>.md`).
- The Orchestrator must have the `Agent` (Task) tool to spawn sub-agents and `SendMessage` to continue them turn-by-turn.
- The apparatus needed for the spec's Observables Required section must be registered as MCPs (or available natively via Bash / Read / Write). The Executor scans at session start and aborts if any required observable has no matching apparatus.
- The operator may need to set up fixtures (test data, accounts, isolated environments) — preconditions in the spec are operator-confirmed before agents spawn.

## Architecture: Two Live Agents

```
                      ┌───────────────────────┐
                      │  Orchestrator (you)   │
                      │  - validates spec     │
                      │  - drives step cursor │
                      │  - writes run log     │
                      └────┬──────────┬───────┘
                           │          │
            spawn + live   │          │   spawn + live
            (multi-turn)   │          │   (multi-turn)
                           ▼          ▼
                    ┌──────────┐ ┌───────────┐
                    │ Executor │ │ Validator │
                    │ "do X"   │ │ "saw X?"  │
                    └─────┬────┘ └─────┬─────┘
                          │            │
                          ▼            ▼
                       real environment (UI, API, shell, fs)
```

**Why live agents instead of spawn-per-step**:
- Browser state persists between steps — an Executor that's already on the target page doesn't need to re-navigate.
- Conversational context lets the Executor reference earlier steps without re-explaining.
- The Validator can ask the Executor for follow-up state without re-loading the run.

**Why two agents instead of one**:
- Bias toward "looks fine, moving on" if the same agent both acts and judges. Independence forces a colder verdict.
- Each context stays focused on its job; the Validator doesn't bloat with browser snapshots; the Executor doesn't pollute working memory with judgment criteria.

## Invocation

```
/behavior-test <slug>
```

The argument is the spec's slug (no path, no extension). The skill resolves the spec via the project's `.flightops/ARTIFACTS.md` configuration (default: `tests/behavior/<slug>.md`).

## Run Lifecycle

### Phase 1: Load + Validate Spec

1. Read `projects.md` to determine the target project's path.
2. Read `{target-project}/.flightops/ARTIFACTS.md` to resolve the behavior-test directory.
3. Read the spec at `{resolved-dir}/<slug>.md`. If missing → STOP with instruction to author one inline (see AUTHORING.md) before running.
4. Validate spec shape — required sections: Intent, Preconditions, Observables Required, Steps table, Out of Scope. If any is missing or empty → STOP with a clear error.
5. Confirm preconditions with the operator. For preconditions that need human action ("operator is logged in", "test fixture exists"), wait for explicit confirmation before spawning agents.
6. Compute run timestamp `YYYY-MM-DD-HH-MM-SS` (UTC).
7. Create the evidence directory `{behavior-test-dir}/<slug>/runs/<ts>/`. Add the runs directory to `.gitignore` if not already there.

### Phase 2: Spawn Executor (live)

Spawn via `Agent` tool with `subagent_type: general-purpose`, using the **Executor: Initial** prompt from `{target-project}/.flightops/agent-crews/behavior-tests-execution.md` (fall back to the skill's shipped defaults if the project's crew file is missing). The initial prompt:

- Establishes the role: "you will perform each step's Actions when I send one. Do not advance until I send the next step."
- Hands over the full spec (so the Executor has context for what's coming).
- Establishes apparatus discovery — "scan registered MCPs by name pattern; report which observables you can measure."
- Establishes the per-step report format.

The Executor returns `[READY]` + its agent ID after scanning apparatus. The Orchestrator keeps the agent ID for SendMessage continuation.

If the Executor signals `[BLOCKED:no-apparatus-<observable>]`, abort the run before Phase 3 (Validator is never spawned).

### Phase 3: Spawn Validator (live)

Spawn via `Agent` tool with `subagent_type: general-purpose`, using the **Validator: Initial** prompt. Same shape:

- Establishes the role: "you will judge each step's Expected Results when I send the Executor's raw state. Do not pre-judge upcoming steps."
- Hands over the full spec (Validator sees what's coming so it can flag spec-level concerns proactively).
- Establishes the per-step verdict format.

The Validator returns `[READY]` + its agent ID, optionally with spec-level concerns reported.

### Phase 4: Step Loop

For each row N in the Steps table (1-indexed):

1. **SendMessage to Executor**: "Step N. Actions: <row.actions>. Perform them; report raw state when done."
2. Receive Executor's response: structured `{actions_taken, raw_state, evidence_paths, executor_notes}`. Save evidence files into the run's evidence dir.
3. **If the row has no Expected Result** (actions-only setup row): record the step in the run log and advance to step N+1 without invoking the Validator.
4. **If the row has no Actions** (wait point): skip step 1 (no Executor call); SendMessage to Validator with Expected Results only, allow polling/timeout.
5. **SendMessage to Validator**: "Step N's raw state from Executor: <executor's structured subset>. Expected Result(s): <row.expected_results>. Render verdict."
6. Receive Validator's response: structured `{verdict, reasoning, evidence_paths, validator_notes}`.
7. **Record step result** in the in-memory run log.
8. **Decide whether to continue**:
   - `pass` → continue to step N+1.
   - `fail` → ask the operator: continue (capture full picture), halt (don't waste time on dependent steps), or rerun-step (give the Executor another shot). Default: continue.
   - `inconclusive` → record as inconclusive; ask the operator whether to continue.

### Phase 5: Teardown

After the last step (or halt):

1. SendMessage to both agents: `[CLOSING]`. Each returns its freeform closing summary.
2. Write the run log file at `{behavior-test-dir}/<slug>/runs/<ts>.md`.
3. Surface a concise summary to the operator.
4. Agents terminate naturally after their `[CLOSING]` response.

### Phase 6: Operator Summary

```
behavior-test run: <slug> @ <timestamp>
  PASS: <n> / <total> steps
  FAIL: <n> / <total> steps
    - Step 3: <one-line reason>
  INCONCLUSIVE: <n> / <total> steps
    - Step 5: <one-line reason>
  Evidence: <evidence-dir>
  Run log:  <run-log-path>
```

If any step failed or was inconclusive, ask the operator: re-run, fix system + re-run, update spec (which loops back to inline authoring during the active conversation), or mark known issue.

---

## Spec Format

The canonical spec format lives in `{target-project}/.flightops/ARTIFACTS.md` under the "Behavior Test — Spec" section. The skill reads each spec at run time and validates its shape against the format expected there. The spec format is repeated here only as a sanity reference; ARTIFACTS.md is authoritative.

```markdown
# Behavior Test: {Title}

**Slug**: `{slug}`
**Status**: draft | active | archived
**Created**: {YYYY-MM-DD}
**Last Run**: {YYYY-MM-DD-HH-MM-SS | never}

## Intent
## Preconditions
## Observables Required
## Steps
| # | Actions | Expected Results |
|---|---------|------------------|
| 1 | ... | ... |

## Out of Scope
## Variants (optional)
```

For authoring guidance (interview shape, row conventions, common pitfalls), see [`AUTHORING.md`](./AUTHORING.md).

---

## Run Log Format

```markdown
# Behavior Test Run: {slug} — {timestamp}

**Spec**: [tests/behavior/{slug}.md](../{slug}.md)
**Status**: pass | fail | partial | aborted
**Started**: {iso8601}
**Completed**: {iso8601}
**Duration**: {hh:mm:ss}
**Executor**: {sub-agent id}
**Validator**: {sub-agent id}

## Summary

{n_pass} / {n_total} steps passed. {n_fail} failed; {n_inconclusive} inconclusive.

## Step Results

### Step {N} — {PASS | FAIL | INCONCLUSIVE | SKIPPED}
- **Actions taken**: {executor's report of what was performed}
- **Raw state**: {one-line summary or excerpt}
- **Expected**: {verbatim from spec}
- **Verdict**: {pass/fail/inconclusive} — {validator's reasoning}
- **Evidence**: [evidence/step-N.png](./{ts}/step-N.png)
- **Validator notes**: {optional}
- **Operator decision**: {continued | halted | rerun-step} (only when step failed)

## Orchestrator Notes
{Decisions made during the run: model preferences, specialized validators spawned, operator interventions.}

## Closing Summaries

### Executor closing
{Executor's freeform closing summary — anomalies, environment hiccups.}

### Validator closing
{Validator's freeform closing summary — spec-quality observations, patterns of failure.}

## Operator Notes
{Post-run reflections.}
```

Evidence directory `{behavior-test-dir}/<slug>/runs/<ts>/` — gitignored. Holds screenshots, snapshot dumps, response bodies, file captures referenced by the run log.

---

## Observability

Two concepts, deliberately distinct:

- **Observable** — a measurable property of the system the test cares about. Toggle state. Response status code. File contents. Audit-log entry. Borrowed from physics: an observable is what can be measured; everything else is metaphysics.
- **Apparatus** — the tool that does the measuring. A browser MCP for DOM observables. `curl` for HTTP observables. A `Read` tool for filesystem observables.

The Executor is **apparatus-agnostic**. The spec's "Observables Required" lists the kinds of observables in human terms; the Executor scans available MCPs at session start to find apparatus that can measure each:

| Observable kind | Apparatus discovery pattern | Example apparatus |
|-----------------|------------------------------|--------------------|
| browser | `*chrome-devtools*`, `*playwright*`, `*browser*` | chrome-devtools MCP, playwright MCP |
| shell | always available via Bash | — |
| http | `*http*`, OR shell + curl | dedicated HTTP MCP, or curl |
| filesystem | always via Read/Bash | — |
| desktop | `*desktop*`, `*accessibility*` | future |

If an observable the spec requires has no matching apparatus, the Executor signals `[BLOCKED:no-apparatus-<observable>]` and the Orchestrator aborts the run before the step loop starts. The Validator is never spawned.

---

## Evidence Handling

- Evidence files live under `{behavior-test-dir}/<slug>/runs/<ts>/`.
- The evidence directory is **gitignored** per the user-global "test snapshots not committed" rule. The skill adds the runs directory to `.gitignore` on first run if not already gitignored.
- Run-log markdown files (`runs/<ts>.md`) are NOT gitignored — they are the artifact of record. Evidence is referenced from the log via relative paths.
- A teammate looking at a committed run log sees the verdict + per-step reasoning + Executor's reports, but does NOT see the screenshots unless they re-run.

---

## Handoff Signals

Crew agents use these signals (Orchestrator parses from agent output):

| Signal | Emitted by | Meaning |
|--------|-----------|---------|
| `[READY]` | Executor or Validator | Agent has loaded the spec; awaiting step instructions. |
| `[STEP:N:done]` | Executor | Step N's actions completed; structured report attached. |
| `[STEP:N:exception]` | Executor | Step N's actions raised an exception; report includes the exception. |
| `[VERDICT:N:pass/fail/inconclusive]` | Validator | Step N verdict rendered; structured verdict attached. |
| `[BLOCKED:no-apparatus-<observable>]` | Executor | Required observable has no matching apparatus; abort the run. |
| `[BLOCKED:reason]` | Executor or Validator | Other blocking reason; abort the run. |
| `[CLOSING]` | Executor or Validator | Closing summary attached; safe for agent to terminate. |

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Spec file missing | STOP; instruct operator to author one inline (see AUTHORING.md). |
| Required apparatus missing for an observable | STOP at Executor's `[READY]`-time apparatus scan; abort with clear error. |
| Executor exception mid-step | Validator still judges the step (based on what was reported); continue per operator's continue/halt/rerun-step preference. |
| Validator times out | Mark the step inconclusive; ask operator; continue. |
| Operator interrupts mid-run | Send both agents `[CLOSING]`; mark run `aborted`; write partial run log. |
| Agent loses context (SendMessage error) | Re-spawn with the full spec + a "resume at step N" instruction. Note the re-spawn in Orchestrator Notes. |

---

## Decision Log

Orchestrator logs decisions in the run log under `### Orchestrator Notes`:

- Which model preferences were applied + why.
- Whether a specialized validator (Accessibility, Visual) was spawned + why.
- Any operator-side intervention (continue, halt, rerun-step decisions per failing step).
- Any agent re-spawn (context loss recovery).

This mirrors the `agentic-workflow` `### Flight Director Notes` discipline: the Orchestrator's decisions are auditable from the run log alone.

---

## Re-runs and Variants

Each re-run gets fresh Executor + Validator agents. Old run logs are kept; the operator prunes manually if desired. The spec is the source of truth across runs — if the system changed but the spec didn't, the run log reflects that.

A spec may declare Variants (parameterized re-runs). The skill runs each variant as a sub-run within the same timestamp directory: `runs/<ts>/variant-A.md`, etc. Overall verdict is PASS only if all variants pass.
