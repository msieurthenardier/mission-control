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

## Execution Modes: Live vs Re-spawn-Per-Step

The architecture above assumes the Orchestrator can both spawn an agent AND continue it across turns (the "live" mode). Some session contexts lose the continuation capability — for example, sessions resumed after auto-summarization may not have the multi-turn agent-continuation tool loaded even though `Agent` is still available. The Orchestrator MUST verify continuation is available at the start of the run; if it isn't, the run falls back to **re-spawn-per-step**: a fresh Executor (and Validator) per row, with the prior step's outcomes summarized into the prompt as context. The fallback is degraded but functional, and is preferable to silently proceeding as if the architecture were intact.

**Re-spawn-per-step caveats** (these are operating-mode constraints, not authoring constraints):

- **Browser apparatus state persists across spawns** because the browser process is shared infrastructure — each new agent can re-attach to the same tabs/pages. Other apparatus state (auth tokens cached in memory, in-process sessions) does not. Spec authors should not assume in-agent context survives a re-spawn.
- **No "ask the Executor" loop**: the Validator cannot reach back to a prior Executor for follow-up state. If the row needs cross-agent collaboration, write the Executor's report richly enough that the Validator can render verdict without follow-up.
- **Long Expected-Result wait windows are an execution risk** in this mode. A single agent that blocks on a long sleep can exhaust its runtime budget before producing a report. Steps with waits longer than ~30 seconds must be split: one spawn performs the Action, the wait happens in the Orchestrator's own real-time (not the agent's), then a second spawn captures the post-state. Alternatively, poll the apparatus on a tighter cadence so each agent invocation returns quickly. The live-agent default avoids this problem because the wait is real time outside the agent's budget; re-spawn does not have that luxury.

The Orchestrator should announce the active mode to the operator before Phase 4 starts, and note the mode in the run log under `### Orchestrator Notes`.

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
6. **Resolve cache mode.** Default is `cold`. If the spec has a top-level `**Cache:** warm` line, mode is `warm`. Pass the resolved mode to the Executor: Initial prompt. Record the mode in the run log's Orchestrator Notes.
7. Compute run timestamp `YYYY-MM-DD-HH-MM-SS` (UTC).
8. Compute the ephemeral evidence directory: `/tmp/behavior-tests/<project-slug>/<slug>/<ts>/`. Create it. **This is never under the project tree.** Evidence files (screenshots, snapshots, eval JSON, log captures) are local-only and not committed — they may contain PII (operator-visible chat, sidebar member lists, env-derived IDs) and are cheap to regenerate by re-running the spec. The only behavior-test artifacts that ever live in the project tree are the spec (`{behavior-test-dir}/<slug>.md`) and the run log (`{behavior-test-dir}/<slug>/runs/<ts>.md`).

### Phase 2: Spawn Executor (live)

Spawn via `Agent` tool with `subagent_type: general-purpose`, using the **Executor: Initial** prompt from `{target-project}/.flightops/agent-crews/behavior-tests-execution.md` (fall back to the skill's shipped defaults if the project's crew file is missing). The initial prompt:

- Establishes the role: "you will perform each step's Actions when I send one. Do not advance until I send the next step."
- Hands over the full spec (so the Executor has context for what's coming).
- Establishes apparatus discovery — "scan registered MCPs by name pattern; report which observables you can measure."
- Establishes the per-step report format.
- **Establishes evidence-fidelity ordering**: for the browser frame, capture rendered state first (screenshot + accessibility snapshot) and treat DOM evals as supplementary diagnostic context, never as primary evidence. An element that's DOM-present but visually missing must be reported as such — `raw_state` describes what would be perceived, not just what was queried. See "Rendered State, Not Internal State" in AUTHORING.md.
- **Establishes cache mode.** Default `cold`: the Executor defeats apparatus cache (fresh browser tab + hard-reload, fresh HTTP connections, no inherited cwd) before signaling `[READY]`. Mode `warm` (spec opt-in via `**Cache:** warm`) skips the defeat. Stale apparatus state masks real bugs — cold is the safe default; warm is only for specs that genuinely depend on prior-run state.

The Executor returns `[READY]` + its agent ID after scanning apparatus and (in cold mode) defeating cache. The Orchestrator keeps the agent ID for SendMessage continuation.

If the Executor signals `[BLOCKED:no-apparatus-<observable>]`, abort the run before Phase 3 (Validator is never spawned).

### Phase 3: Spawn Validator (live)

Spawn via `Agent` tool with `subagent_type: general-purpose`, using the **Validator: Initial** prompt. Same shape:

- Establishes the role: "you will judge each step's Expected Results when I send the Executor's raw state. Do not pre-judge upcoming steps."
- Hands over the full spec (Validator sees what's coming so it can flag spec-level concerns proactively).
- Establishes the per-step verdict format.
- **Establishes frame-aware judgment**: when an Expected Result is marked `[mixed-frame]`, weight the observable in the same taxonomy as the row's Action; the cross-frame observable is supplementary, present only to distinguish internal states the user-facing observable collapses. A pass on the user-facing observable plus a fail on the supplementary observable is a real fail (the system is behaving differently from the spec's distinguishing case); a fail on the user-facing observable is a fail regardless of the supplementary observable. See "Same Observable Taxonomy" in AUTHORING.md.
- **Establishes rendered-state precedence**: weight screenshot and a11y observations above DOM-state observations. An element that's DOM-queryable but not rendered (broken CSS, hidden ancestor, zero-sized chrome) is a fail at the user-perceivable level even when the DOM agrees with the Expected Result. The Validator's verdict reflects what a user sees, not what JavaScript can read. See "Rendered State, Not Internal State" in AUTHORING.md.

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
- **Evidence**: `step-N-screenshot.png`, `step-N-snapshot.txt` (ephemeral; see file header note)
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

The run log should include a header line noting the ephemeral evidence path used for this run, e.g.:

```
**Evidence (ephemeral, local-only, not committed)**: lived at `/tmp/behavior-tests/<project>/<slug>/<ts>/` during the run; re-derivable by re-running the spec.
```

This makes the local-only nature explicit to anyone reading the committed run log later.

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

- Evidence files live at an **ephemeral path outside the project tree** (default: `/tmp/behavior-tests/<project-slug>/<slug>/<ts>/`). They are never committed and never written into the project's source tree.
- The reason is twofold: (a) evidence files routinely contain operator-visible UI surfaces with PII (member lists, real-name peers, profile chrome, env-derived IDs), (b) screenshots and per-step JSON dumps would bloat the repo with content that a fresh test run regenerates cheaply.
- Run-log markdown files (`{behavior-test-dir}/<slug>/runs/<ts>.md`) DO live in the project tree and are committed — they are the artifact of record. The run log captures the prose evidence (verdicts, raw_state descriptions, Validator reasoning) that survives without the binary artifacts.
- Per-step entries in the run log reference evidence files by name only (e.g., `\`step-3-screenshot.png\``), without paths — the file names identify what was captured; the bytes only exist on the original run's machine.
- A teammate reading a committed run log sees the verdict + per-step reasoning + Executor's structured reports. To inspect the bytes, they re-run the spec.

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
