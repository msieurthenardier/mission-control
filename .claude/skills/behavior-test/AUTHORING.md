# Authoring Behavior Test Specs

A behavior test spec is a markdown file that defines what the system should do (Actions) and how to tell that it did (Expected Results), in a two-column table that a human could execute by reading top-to-bottom. The `/behavior-test` skill runs the spec with two live AI agents — an Executor that performs the Actions and an independent Validator that judges the Expected Results.

**Specs are authored inline during planning conversations** — there is no `/behavior-test author` command. When the operator and the Orchestrator are designing a flight, leg, mission, debrief, or maintenance finding and identify a verification need that warrants a behavior test, the Orchestrator drafts the spec file directly using the format below. This guide is what the Orchestrator consults to do that well.

The canonical spec format lives in `{target-project}/.flightops/ARTIFACTS.md` under "Behavior Test — Spec". This guide covers the *process* of writing one well — when to author, what questions to ask, what mistakes to avoid.

## The Verification Model: Witnessed Behavior

A behavior test follows the **Witnessed** pattern: every action the system takes is judged by an independent agent. The agent that did the work is never the same agent that decides whether the work was correct.

This pattern enforces a separation that human manual testing doesn't — a human tester usually both performs and judges, biasing toward "looks fine, moving on." The Witness pattern forces a colder verdict by structurally separating the roles.

A well-written spec exploits this separation: actions are imperative ("do X"); expected results are observable ("Y is true"); the Validator can render verdict from the Executor's report without re-doing the work.

## The Foundational Pair: Observable + Apparatus

Two concepts the spec is built on:

- **Observable** — a measurable property of the system the test cares about. Toggle state. Response status code. File contents. Audit-log entry. Borrowed from physics: an observable is what can be measured; everything else is metaphysics.
- **Apparatus** — the tool that does the measuring. A browser MCP for DOM observables. `curl` for HTTP observables. A `Read` tool for filesystem observables.

**The testability discipline** (Popper applied to behavior tests): every Expected Result must reference at least one observable. If you can't write a measurable Expected Result, the system isn't observable at this layer — find a coarser surface or wire instrumentation. A spec row that says "the user feels confident" is not testable; a row that says "the success banner is in the DOM" is.

If the operator stalls when asked "what's the observable for that expected result?", the spec isn't ready. That's the load-bearing question of authoring.

## Rendered State, Not Internal State

Within a single observable taxonomy, prefer the form of the observable that reflects what a real observer would perceive, not the form that's easiest to query. For the browser frame in particular: prefer **rendered state** (what the user actually sees) over **internal state** (what the DOM happens to say).

Concretely:
- **A screenshot** is the strongest evidence of rendered state — it captures the literal pixels.
- **The accessibility tree** (a11y snapshot) is the second-strongest — it's the system's contract for what assistive tech (and by extension a perceiving user) can know about the page.
- **The DOM** is weaker. An element can exist in the DOM with `.checked === true` while being styled `display: none`, sized 0×0, clipped out of viewport, or positioned off-screen. A spec or eval that reads `.checked` and sees `true` will declare "the toggle is on" even when no human can possibly see a toggle.

The same hazard exists in non-browser frames in milder form: shell `echo` may write to a closed FD; an HTTP endpoint may return 200 with an empty body; a file may exist but be unreadable. Observe what would be perceived, not what would be queried.

**For specs**: write Expected Results in user-perceivable terms ("the toggle is visible and unchecked", "the success banner appears", "the chart shows three bars"). Do not write Expected Results that reference DOM internals (`#cf-toggle.checked === true`, `[data-foo=bar] is present`). Channel coupling at the Expected Result level is the same pitfall as channel coupling at the Action level (see "Channel coupling in Actions" in Common Pitfalls).

**For evidence at run time**: the Executor captures screenshots and a11y snapshots first; structured DOM evals are supplementary and used only when they add information the higher-fidelity evidence doesn't (e.g., reading the value of a non-visible internal state for diagnostic context, never as primary evidence).

**For verdicts**: the Validator weights screenshot and a11y observations above DOM evals. An element that's queryable but not rendered is a real-world failure; the Validator should call it that way, not pass it because the DOM agreed.

This rule earns its keep in cases like a toggle whose JavaScript correctly tracks state but whose CSS class is broken — the DOM says the state is right; the user sees nothing. A behavior test that validates the DOM will pass; a behavior test that validates the rendered UI will fail. The latter is what the test is for.

## Same Observable Taxonomy — The Frame Discipline

Within a single row of the Step Table, the Actions and Expected Results should belong to a **similar observable taxonomy** — the categories listed in "Observables Required" (browser, shell, http, filesystem). Action in the browser frame ("click the toggle") → Expected Result in the browser frame ("the success banner appears"). Action in the shell frame ("run `./script.sh`") → Expected Result observable through the shell ("exit code 0, stdout contains 'ok'").

A behavior test models how a real observer experiences the system. A user posting a Discord message sees the bot's reply (browser); they don't see the SQLite audit log (filesystem). A test that asserts "the bot replied AND the audit log shows `disposition=stepped`" mixes frames — the technical observable adds precision, but it also couples the test to internal implementation a user-facing test shouldn't depend on. Lean toward the human-friendly observable; treat technical observables as escape hatches that justify themselves.

**When crossing frames is legitimate**:
- The system has multiple internal states that collapse to the same user-facing outcome (e.g., "bot is silent" could mean "policy decided no" OR "system error" — only the audit log distinguishes).
- The action triggers an asynchronous side effect with no UI surface (email sent, webhook fired, queue job enqueued).
- The test is verifying internal contracts (migration ran, secret rotation took effect, cache invalidated).

When you do cross frames, mark the row with `[mixed-frame]` in the Expected Results cell and add a one-sentence justification. If the cross-frame observable is being used to distinguish internal states the user can't see, also note the gap as system observability debt — the UI might benefit from surfacing the distinction.

## When to Author a Behavior Test

Trigger points during planning conversations:

| During | Author one when… |
|---|---|
| `/flight` planning | The flight's verification approach needs real-environment observation that a unit test can't provide. |
| `/leg` planning | A leg's acceptance criterion can only be verified by acting on the running system. |
| `/mission` planning | The mission's success criteria include behaviors that span multiple components and surfaces. |
| `/routine-maintenance` | A finding is worth a regression gate — make the test now so future flights can re-run it. |
| `/flight-debrief` / `/mission-debrief` | A debrief surfaces "we should have caught this with a test" — author it as a follow-up action. |

**Anti-pattern**: authoring a behavior test for something a unit test already covers. The behavior-test format is heavyweight (two live agents, evidence directory, run logs). Use it for tests where the cost is justified by the value of real-environment observation.

## The Interview Shape

When you (the Orchestrator) and the operator decide to author one, walk through these questions in order:

### 1. Intent

"What does this test verify? One sentence."

Listen for vagueness. "Verify the signup flow works" is too broad; "Verify a new user can sign up with a valid email and reach the welcome page" is right-sized.

### 2. Why this paradigm

"Why does this need a behavior test instead of a unit test?"

Common right answers: needs the real browser; needs the real database; needs to span UI + API; needs to verify AI agent behavior; needs to be run after every deploy.

Common wrong answers: "Because I'm comfortable with this format" (use a unit test); "Because we don't have unit tests yet" (write the unit test).

### 3. Observables

"What observables does the test read?"

Group by surface: browser observables (DOM state), HTTP observables (response codes + bodies), shell observables (stdout / stderr / exit code), filesystem observables (file contents). These become the "Observables Required" section of the spec; the run skill matches them against available MCPs at run time.

### 4. Preconditions

"What must be true before the test starts?"

Each precondition should be operator-checkable: "the app is running on X URL", "a test fixture file exists at Y", "the operator is logged in to Z". These get confirmed by the operator before agents spawn at run time.

Avoid hidden preconditions ("the database has the default seed data") — make them explicit so a future operator running the test in a fresh environment doesn't get mystery failures.

Preconditions that can decay over time — external services, authenticated sessions, warm caches, time-bounded credentials, background workers — should be paired with an **active verification**, not just a declaration. Either include a precondition-check step at the top of the spec that probes the live state, or note a precheck script the operator runs immediately before invoking the test. A precondition that's true at authoring time and false at run time is a silent test failure waiting to happen, often surfacing several steps later as a confusing cascade.

**Cache mode.** Default is `cold` — the Executor defeats apparatus cache (fresh tab, hard-reload, fresh HTTP connections) before Step 1. To opt into `warm`, add this line near the top of the spec (before Preconditions):

```markdown
**Cache:** warm
```

Use `warm` only when the spec depends on prior-run state (session-restore from `localStorage`, browser-cache behavior itself, a flow that needs `sessionStorage` from a prior page). Document the reason in Intent so the directive isn't accidentally removed.

### 5. The Step Table — the load-bearing work

This is where you build the Zephyr-style two-column table.

**One row = one logical checkpoint.** A row may bundle multiple Actions in sequence and multiple Expected Results, but the Validator's verdict for that row covers everything in it.

Walk through the test step-by-step with the operator:

> "OK, step 1. What's the first action?"
> ... "And what's observable after step 1?"
> "Step 2. Next actions?"
> ... "Observable?"

Until the test is complete.

**Row conventions to enforce as you write**:

- **Actions are imperative and human-readable**: "click X", "type Y", "POST to /api/foo with body {bar}", "read file /etc/hosts" — not pseudo-code. A human running this test should be able to follow.
- **Expected Results are observable**: "bot replies with substring 'pong'", "API responds 200 with `enabled: true`", "file contains the new line". Bind every claim to an observable.
- **A row can have Actions only (no Expected Result)** — useful when setting up state. The Validator skips judgment and the Orchestrator advances. Mark "(setup row, no judgment)" in the Expected Results cell.
- **A row can have Expected Results only (no Actions)** — useful as an asynchronous waitpoint. Mark "(wait point, no actions)" in the Actions cell. The Validator polls or observes until the expected result is met or a timeout elapses.
- **Use `[a11y]` markers** on Expected Results that need accessibility judgment — picked up by the optional Accessibility Validator at run time.
- **Stay in the observer's frame**: Actions and Expected Results within a row should share an observable taxonomy. Browser → browser, shell → shell, etc. Cross-frame rows need a justification and a `[mixed-frame]` marker. See "Same Observable Taxonomy" above.
- **Defeat client-side caching across mutation boundaries**: If Step N modifies state that a later step expects to observe through the same client, the later step's Action should begin with a deliberate cache defeat (hard reload, re-fetch, or whatever the apparatus exposes). Single-page applications and other client-side caches commonly serve stale in-memory state on navigation without re-fetching from the backend, masking the mutation and producing a false-pass or confusing false-fail. Don't assume the client noticed.

### 6. Out of Scope

"What does this test NOT verify? What other tests cover those areas?"

This prevents the spec from drifting to "the test that checks everything." If the operator can't name what's out of scope, push back — every test has boundaries; making them explicit saves later re-litigation.

### 7. Variants (optional)

"Should this test be re-run with different parameters? E.g., same test against different user roles, different inputs, different environments?"

Variants get a sub-section listing each variant's input deltas. The run skill executes each variant as a separate sub-run; overall verdict is pass-only-if-all-variants-pass.

### 8. File It

Write the spec to the project's behavior-test directory (per `.flightops/ARTIFACTS.md`; default `tests/behavior/<slug>.md`). Status starts as `draft`. The operator promotes to `active` once they've reviewed.

If the spec path already exists, ask: overwrite, version-suffix (`<slug>-v2`), or abort. The operator decides.

## Spec Format (Authoritative Reference)

The format lives in `{target-project}/.flightops/ARTIFACTS.md` under "Behavior Test — Spec". A skeleton:

```markdown
# Behavior Test: {Title}

**Slug**: `{slug}`
**Status**: draft | active | archived
**Created**: {YYYY-MM-DD}
**Last Run**: {YYYY-MM-DD-HH-MM-SS | never}

## Intent
One paragraph: what this test verifies and why this paradigm fits.

## Preconditions
- Each precondition is operator-checkable.

## Observables Required
- browser (DOM state, page content — measured via chrome-devtools / playwright / similar)
- shell (stdout, stderr, exit code — measured via Bash)
- http (response status / body / headers — measured via curl via shell or dedicated MCP)
- filesystem (file contents, directory listings — measured via Read / Write / Bash)

## Steps

| # | Actions | Expected Results |
|---|---------|------------------|
| 1 | {imperative actions, human-readable} | {observable expected results} |
| 2 | (setup row, no judgment) | (empty) |
| 3 | (wait point, no actions) | Within {timeout}, {observable result}. |

## Out of Scope
- What this test does NOT verify; link related tests.

## Variants (optional)
- Each variant's input deltas.
```

## Common Authoring Pitfalls

**Under-spec'd Expected Results.** "The page looks right" is not observable. Force the operator to bind the claim to something a Validator can measure: "the page contains the text 'Welcome, {username}'", "the page's `<h1>` element has text matching `/Welcome/`", etc.

**Over-bundled rows.** A row that says "click through the entire signup flow and verify everything works" hides too much. If the verification fails, the Validator can't tell which step actually broke. Split into one row per logical checkpoint.

**Under-bundled rows.** Conversely, one row per click drowns the test in trivial steps. If the only Expected Result you can write for "click the submit button" is "the button was clicked" — that's not a step worth its own row. Bundle the click into the row that has the observable consequence.

**Missing observables for hidden side effects.** If the action triggers something asynchronous (email sent, webhook delivered, queue job enqueued), the Expected Results section should reference an observable for that — DB row, log line, HTTP request to a webhook receiver. Hidden side effects that aren't observable will silently regress and the test won't catch them.

**Assumptions in Preconditions that aren't actually checked.** "The database is clean" is a precondition. If the operator can't actually verify it (no UI, no API endpoint), either add a step to make it observable or replace with a more concrete precondition ("the operator ran `./scripts/reset-db.sh` within the last 60 seconds").

**Declared-but-decaying preconditions.** Worse than an unchecked precondition is a precondition that was true at authoring time but can silently lapse — token expiry, warm-cache cooldown, external-service availability, background-worker liveness. Pair every decay-prone precondition with an active probe at run time, either as a precondition-check step in the spec or as a precheck script the operator runs before invoking the test.

**No Out of Scope section.** Tests without explicit boundaries drift to verifying everything, become slow + fragile + hard to maintain. Authoring is incomplete without naming what the test doesn't cover.

**Channel coupling in Actions.** Writing "execute `document.querySelector('[data-toggle]').click()`" couples the Action to a specific browser-automation API. Write "click the toggle" instead; the Executor figures out which apparatus performs the click. The spec stays apparatus-agnostic; the operator can read it; future Executors with different MCPs still understand it. The same rule applies to Expected Results — write "the toggle is checked", not "`#toggle.checked === true`".

**Cross-frame Expected Results.** A row where the Action is a UI click but the Expected Result is a database query has slipped out of the user's frame. The technical observable might be correct, but the test no longer models the user's experience. Default to the same observable taxonomy as the Action; cross frames only when the user-facing observable can't distinguish the cases you need to distinguish, and when you do, mark `[mixed-frame]` and justify in one sentence. See "Same Observable Taxonomy" above.

**DOM-checked-but-invisible.** Within the browser frame, an Expected Result like "the toggle is checked" is satisfied by `.checked === true` even when the toggle is styled `display: none`, sized 0×0, or rendered with no visible chrome (broken CSS class, missing wrapper component). The DOM is happy; the user sees nothing. Specs and Validator verdicts must rest on what's actually rendered — screenshot + a11y tree — not on what's queryable. See "Rendered State, Not Internal State" above.

## Iterating on Specs

Behavior-test specs evolve with the system. When a test fails after a deliberate behavior change:

- **System changed; spec didn't** — update the spec. Bump `Last Run` after the next successful run.
- **System changed; spec was always wrong** — update the spec and note in the next run log why the prior expectation was wrong.
- **System didn't change; spec found a real regression** — leave the spec; fix the system.

Old run logs survive after spec edits; they capture the system's behavior at that timestamp. The spec captures the current contract. Both are useful — operators reading the history can see "we expected X, then changed to expect Y, then regressed."

## Filing the Spec Inline

When you write the spec during a planning conversation, treat it as a code artifact:

1. Use the `Write` tool to create the spec file at the right path (per ARTIFACTS.md).
2. Commit it with the rest of the planning artifacts in the same commit (or note it as a follow-up commit if the planning artifacts are batched separately).
3. Reference the spec slug in the parent artifact's acceptance criteria — e.g., a leg artifact may say "Run `/behavior-test <slug>` to verify acceptance".
4. Don't run the test as part of authoring. Authoring produces the spec; running is a separate operation (the run skill spawns the live-agent crew, which is heavyweight). Run when the system is ready to be tested, not during planning.
