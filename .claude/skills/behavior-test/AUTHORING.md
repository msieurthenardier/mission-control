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

**No Out of Scope section.** Tests without explicit boundaries drift to verifying everything, become slow + fragile + hard to maintain. Authoring is incomplete without naming what the test doesn't cover.

**Channel coupling in Actions.** Writing "execute `document.querySelector('[data-toggle]').click()`" couples the Action to a specific browser-automation API. Write "click the toggle" instead; the Executor figures out which apparatus performs the click. The spec stays apparatus-agnostic; the operator can read it; future Executors with different MCPs still understand it.

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
