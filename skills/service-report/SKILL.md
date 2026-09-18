---
name: service-report
description: Sweep this project's accumulated debriefs for recurring Flight Control methodology trends and report them upstream as GitHub issues on the mission-control repository. Operator-invoked whenever they choose, typically after several missions. Clusters observations across debriefs into trends, searches existing issues first and joins one where the root cause matches, generalizes until no project information remains, and sends nothing without explicit approval of the exact text.
---

# Service Report

In aviation a **squawk** records a defect in *this* aircraft, cleared by *this* operator. A **service difficulty report** runs the other way: the operator tells the manufacturer the type design has a problem, because every other operator will hit it too. Manufacturers act on the pattern across the fleet, not on the first report.

A service report carries one recurring Flight Control methodology **trend** to `msieurthenardier/mission-control`, generalized until nothing about the project remains.

**Two rules override everything else here:**

1. **Nothing leaves the project until the operator approves it.** That covers every outbound act: the search query, the issue body, a comment, a reaction. No summary approval, no batch approval, no unattended path.
2. **If it cannot be said without project information, it cannot be filed.** There is no workaround.

## When to Use

**Whenever the operator chooses.** This skill is not attached to any debrief, any phase gate, or any schedule. Nothing invokes it automatically and no other skill hands off to it.

In practice that means after several missions, when there is enough accumulated material for patterns to be visible. Debriefs are the instrument; this is the periodic read of what they recorded. Running it after every mission produces events, not trends — and events are what floods a tracker.

A sweep re-reads the whole corpus every time, by design. A pattern that sat below the threshold six months ago may have crossed it since, and the same observations legitimately support a stronger report later. Re-reporting is prevented by checking what this project already filed, not by narrowing the window.

## Prerequisites

- `.flightops/ARTIFACTS.md` exists with service report conventions — run `/mission-control:init-project` to apply migration 009 if missing
- **Upstream reporting is affirmatively enabled for this project.** Read `ARTIFACTS.md` and find the project's setting for whether methodology findings may be reported upstream. If you cannot determine that it is affirmatively enabled — the setting is absent, unset, ambiguous, or the project uses an artifact backend that does not carry it — **stop** and ask the operator to set it. Do not infer consent from silence. This gate fails closed by design: some organizations forbid posting anything to public repositories, and the cost of asking is one question
- Enough corpus to sweep. One mission's worth of debriefs cannot show a trend; say so and stop rather than reporting events
- `gh` authenticated. Without it, everything up to submission still runs and the operator gets the finished text plus a link to paste

## Invocation

```
/mission-control:service-report                 Sweep the corpus for recurring methodology trends
/mission-control:service-report {hypothesis}    Sweep, focused on one suspected trend
/mission-control:service-report list            Local report log with upstream status
```

The `{hypothesis}` form is **not** a report to file. It is the operator saying "I think this keeps happening" — the sweep then goes looking for corroboration in the corpus, and reports what the evidence supports, including "the debriefs do not bear this out." A hunch with no record behind it is not a trend, and filing one would be the exact failure this skill exists to avoid.

## Pipeline

### 1. Survey the corpus

Read every artifact in this project that records how the methodology behaved. Locate them per `ARTIFACTS.md`:

- **Mission debriefs** — methodology feedback, process analysis, lessons learned
- **Flight debriefs** — skill-effectiveness analysis, what could be improved, deviations
- **Maintenance reports** — findings attributed to process rather than code
- **Escalated squawks** — a squawk that failed its qualification gate often marks a place where the methodology mis-sorted the work

Extract observations, not summaries. For each: what the methodology did, what was expected, what it cost, which skill and phase, which flight and mission, the date, and the plugin version in use if recorded.

Report the span you covered — how many missions, how many flights, what date range.

### 2. Cluster into candidate trends

This is the substance of the sweep, and the part that cannot be done by matching words.

Debriefs written months apart describe the same friction in different language, by different agents, at different levels of detail. **Cluster on what the methodology did, not on how it was worded.** Two rules keep clusters honest:

- **Do not cluster on the skill name alone.** Two unrelated defects in `flight-debrief` are two trends, not one "flight-debrief is awkward" trend. That collapse is the single most common way a sweep produces something unactionable.
- **Apply the root-cause test to every cluster**: would **one change to the methodology** remove every observation in it? If not, split it.

For each cluster record: the observations it contains, the flights and missions they span, the date range, the plugin versions involved, and the aggregate cost.

### 3. Apply the trend threshold

A cluster is a trend when it has **independent observations in at least three debriefs spanning at least two missions**.

Below that it is an event. Leave it in the corpus and say so — the next sweep will pick it up if it keeps happening. Do not report events; that is the granularity problem this skill exists to avoid.

The operator may override the threshold for something they judge important. If they do, the report carries `below threshold` in its occurrence line and the local artifact records the override. Label it honestly rather than letting it pass as a pattern.

**Version span matters as much as count.** A trend whose observations start at plugin 0.9 and continue at 1.0 survived a release; one that stops at 0.9 was probably fixed. Check the latter against upstream before reporting it at all — that is gate criterion 3, and the sweep is where it usually fires.

### 4. Gate

Each trend is reportable only if **all five** hold:

1. **Reproduces from the methodology alone** — an operator on a different stack, language, and domain would hit it
2. **Has an observed cost** — rework, a re-run, a wrong artifact, a missed gate, accumulated across occurrences. Not "would be nicer if"
3. **Not already fixed upstream** — check the plugin versions in the trend's span against upstream main and closed issues
4. **Not project-owned surface** — not something `ARTIFACTS.md` or the crew files are meant to own. Those are customizable by design; friction there is a local edit, and a trend confined to them is a signal to make that edit
5. **Statable with zero project information**

Say out loud which criterion a rejected trend failed, and where it goes instead:

| Failed | Goes to |
|--------|---------|
| 1 | Stays a project lesson |
| 2 | Stays a project lesson |
| 3 | `/mission-control:preflight-check`, then `/mission-control:init-project` |
| 4 | A local edit to `ARTIFACTS.md` or the crew file — and the sweep just proved it is worth making |
| 5 | Nowhere. It cannot be filed |

Criteria 3 and 4 reject more than expected. Most "the methodology is broken" turns out to be drift or local customization, and a sweep is the best chance to notice which.

### 5. Build the deny-list

Before any text is drafted, collect the strings that must never appear in anything sent upstream. This is a mechanical check that runs before human or model judgment, and it is the only deterministic control in the pipeline:

```bash
git remote -v                      # host, owner, repository name
basename "$PWD"                    # project directory name
git config user.name               # operator identity
git config user.email
git log -1 --format='%an %ae'
ls -d */ 2>/dev/null               # top-level directory names
```

Add the package manifest's project name where one exists (`package.json` `name`, `pyproject.toml` `name`, `Cargo.toml` `name`, `go.mod` module path), the operator's home directory path, and the project's own domain nouns as they appear in its `README.md` title and `CLAUDE.md` opening.

**Filter the list** before using it: drop tokens under four characters, and drop generic directory names that would match innocent prose — `src`, `lib`, `app`, `api`, `bin`, `cmd`, `pkg`, `test`, `tests`, `docs`, `build`, `dist`, `internal`, `vendor`, `node_modules`. A deny-list that fires on every draft gets ignored, which is worse than no deny-list.

Keep it for steps 6 and 8.

### 6. Generalize

**Write the trend from scratch in methodology vocabulary. Never copy debrief prose and scrub it** — that is how leaks survive. The corpus is written in the project's own language throughout, so this step matters more here than anywhere else in Flight Control.

Methodology terms (`leg`, `flight`, `acceptance criteria`, skill and artifact names) are the shared vocabulary and belong in the report. Project terms do not. The test: *the report must be reconstructible from the methodology alone.* If a reader needs to know what the project does, it is not ready.

Be specific without being proprietary. "A leg whose acceptance criteria named an interface the flight had not specified" is specific. "Leg 03 of the billing-sync flight" is proprietary. "The leg specs were unclear" is neither.

Describe the **pattern**, then one generic instance of it. Not five instances — one, chosen because it is the clearest, with the count carrying the weight the other four would have.

### 7. Search before drafting — with the query approved first

A search query is an outbound request. GitHub receives it, it is attributable to the operator's account, and it lands in their search history. It is covered by rule 1 like everything else.

**Build the query from a closed vocabulary only**: skill names, artifact names, lifecycle state values, signal names, and phase names — all enumerable from the plugin itself. No project terms, no free text lifted from the corpus. Run the query against the deny-list from step 5. Then show the operator the literal query strings and get a yes before running anything.

On approval, search in this order:

1. **This project's own service reports**, at the location `ARTIFACTS.md` defines. A sweep re-reads the whole corpus, so this is what stops it re-filing what it filed last time
2. **Upstream open issues**, then **closed issues separately** — closed issues answer gate criterion 3, and sharing one result budget with open issues buries them:
   ```bash
   gh issue list --repo msieurthenardier/mission-control --state open   --search "{terms}" --limit 60
   gh issue list --repo msieurthenardier/mission-control --state closed --search "{terms}" --limit 60
   gh search issues --repo msieurthenardier/mission-control --limit 60 "{terms}"
   ```
3. **Open PRs and recent commits**, for a fix already in flight:
   ```bash
   gh pr list --repo msieurthenardier/mission-control --state open --search "{terms}" --limit 30
   gh api repos/msieurthenardier/mission-control/commits --jq '.[].commit.message' | head -50
   ```

Classify into exactly one:

| Outcome | Action |
|---------|--------|
| **New** | Draft an issue |
| **Recurred** — this project already reported it, and the trend has continued since | React `+1`, then comment the updated count and span. This is the most valuable comment the skill produces |
| **Variant** — same root cause, different manifestation, reported by someone else | React `+1`, then comment the occurrence |
| **Duplicate** — same root cause, nothing new to add | React `+1`. No comment |
| **Already fixed** | Not an issue. Route to `/mission-control:preflight-check` |

**Apply the root-cause test, out loud, before choosing anything other than new:**

> Would **one change to the methodology** fix both this trend and the existing issue?

Yes → recurred, variant, or duplicate. No → **new**, even though new is the exception. Joining is the default, not the answer. Two distinct defects filed under one issue cannot be separated afterwards without hand-reading every comment on it, and the operator who could tell them apart is gone by then. Superficial similarity — same skill, same phase, same words — is not root-cause identity.

### 8. Draft

**New issue.** Title ≤ 80 characters, stating the difficulty, not the fix. Body:

```markdown
### What happens
One sentence describing the pattern.

### What was expected
One sentence.

### Cost
What it has cost across occurrences — rework, re-runs, wrong artifacts, missed gates.

### Repro
Two or three lines. One generic instance, minimal, in methodology terms.

---
Plugin: {versions spanned, e.g. 0.9.2–1.0.1}
Skill: {skill name}
Phase: {phase name, or —}
Occurrences: {N} flights across {M} missions
Span: {YYYY-MM} to {YYYY-MM}
```

**Recurred / variant comment.** Shorter, same trailer:

```markdown
### Continued occurrence
- Matches the report: {what is the same}
- Differs: {the one dimension that differs, or "nothing new — count only"}
- Since last reported: {what has accumulated}

---
Plugin: {versions spanned}
Skill: {skill name}
Phase: {phase name, or —}
Occurrences: {N} flights across {M} missions
Span: {YYYY-MM} to {YYYY-MM}
```

That trailer is fixed-format on purpose. It is the only thing that makes a corpus of reports countable — which skill, which phase, which versions, how often, over how long — and it has to appear identically on issues and comments alike or there is nothing to aggregate. **Span and version range are the trend evidence**: "still happening eight months and two releases later" is the claim a maintainer can act on.

The `Differs` line is the point of the comment. Each occurrence either matches the issue exactly or names the one dimension it varies on. That tightens an issue's scope as reports accumulate instead of scattering it across near-duplicates — and when the `Differs` lines on an issue stop clustering, that is the signal the issue is carrying more than one defect and should be split.

**Style, enforced:**

- Terse. Whole body under 200 words, however large the trend
- Plain words. No throat-clearing, no framing, no gratitude
- **Report the difficulty, not the redesign.** No proposed solution section. Operators report difficulties; the maintainer designs the fix. At most one line of `Suggested direction:` and only if the operator asks for it
- No quality adjectives — "confusing", "clunky", "awkward" — without the observable that produced them
- Counts, not anecdotes. The evidence is that it kept happening; one instance illustrates, it does not argue
- If two operators could not recognise the same thing from the text, it is not specific enough yet

### 9. Redaction review

Two checks, in this order. The first is mechanical and authoritative; the second is judgment.

**9a. Deny-list match.** Case-insensitive substring search of every filtered deny-list token against the draft body, the title, and the query strings. **Any hit is a hard fail** — return to step 6 and rewrite. Do not "fix" a hit by deleting the word; a draft that contained the project's name was written from the wrong material.

**9b. Reviewer pass.** Spawn a Redaction Reviewer (Task tool, `subagent_type: "general-purpose"`). Instruct it directly — there is no crew file for this, and none should be added.

Be honest about what this reviewer is and is not. **It is not context-free.** A spawned agent inherits the project's `CLAUDE.md`, which in most projects names the project, its domain, and its stack. It therefore cannot judge "would an outsider recognise this project?" — it already knows the answer and will read a generalized phrase as obviously generic because it knows the referent. That failure mode is why 9a exists and runs first.

What it *can* do is catch what a deny-list cannot: phrasing that only makes sense to someone who knows the project. Ask it exactly that:

- Give it the draft text, the deny-list, and nothing else. Tell it not to read project files
- Its question: **which sentences here would be unintelligible, or would raise a "what are they talking about?", for a reader who knows only the Flight Control methodology?** Those sentences are carrying project context implicitly
- Have it also check the explicit classes: usernames or home paths; repo, org, or product names; customer or partner names; internal hostnames or URLs; credentials, keys, tokens; project file paths; project code; artifact excerpts; stack traces; ticket ids; domain vocabulary
- It returns `[CLEAR]`, or the specific spans that fail and why

Any failure goes back to step 6 for a rewrite, not a patch.

### 10. Approve

Show the operator the exact text that will be sent, verbatim, not summarized — and name the act. Per branch:

| Branch | Show |
|--------|------|
| **New issue** | Repository, title, full body |
| **Recurred / Variant** | Repository, issue #N and its title, the full comment body, and that a 👍 reaction goes with it |
| **Duplicate** | Repository, issue #N and its title, and that this posts a 👍 reaction — no text |
| **Already fixed** | Nothing is sent. Say so and route onward |

State plainly: **this posts publicly, under your GitHub account.** A reaction is a public, attributable act and gets the same question as an issue body; it is not exempt for being small.

A sweep may surface several trends at once. **Approve them one at a time.** The operator sees each body and answers for it; there is no "yes to all", because a batch approval is an approval of a summary, and rule 1 is about exact text.

Then ask. Send, edit, or withhold.

**Stop at `draft` if you cannot put this question to a person and get an answer before continuing** — a spawned agent, a scripted or scheduled run, any session with no human present. This skill is operator-invoked by design, so that situation should not arise; if it does, something has gone wrong upstream of here.

### 11. Submit

Write the approved body to a scratch file outside the project tree (`mktemp`), submit, then delete it:

```bash
# New
gh issue create --repo msieurthenardier/mission-control \
  --title "{title}" --body-file {scratch}

# Recurred / Variant — react, then comment
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
gh issue comment {N} --repo msieurthenardier/mission-control --body-file {scratch}

# Duplicate — react only
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
```

No `--label`: label names are resolved against the repository and a missing one fails the create outright. Labelling is the maintainer's triage step.

**On failure — auth expired, rate limit, a 404 on the issue number, a network error — stop and report it to the operator.** If they ask to retry, retry with **the approved bytes verbatim**. Never re-draft, re-word, or trim a body to make a submission succeed: the operator approved specific text, and anything else posting under their account is a rule 1 violation arriving through the back door.

No `gh` at all: hand the operator the body and `https://github.com/msieurthenardier/mission-control/issues/new`. Record the report as `draft` — it is not submitted until they say it was.

### 12. Record

Write the artifact per `.flightops/ARTIFACTS.md`, including the submitted text **verbatim**. The artifact is the local audit trail of exactly what left the project, and the evidence trail the next sweep reads to know this trend was already reported.

Record the supporting observations — which debriefs, flights, and missions the trend was drawn from. Those are local references and **never appear in anything sent upstream**.

Set status by branch:

| Branch | Status |
|--------|--------|
| New issue created | `submitted` |
| Recurred / variant — reaction + comment | `merged` |
| Duplicate — reaction only | `merged` |
| Operator declined to send | `withheld` |
| No `gh`, text handed over | `draft` |
| Gate or redaction failure, abandoned | `withheld`, with the reason |

Close the sweep by reporting: the span covered, the clusters found, which crossed the threshold, which were filed or joined, and which were left in the corpus to see whether they keep happening.

## Verb: list

Check the project's upstream reporting setting first, exactly as the prerequisites describe. A project that has opted out does not get outbound calls from this verb either.

Read the service report artifacts at the location `ARTIFACTS.md` defines. Report id, title, status, upstream link, the trend's occurrence count and span at time of filing, and age.

For any record carrying an issue number — `submitted` or `merged` — refresh upstream state:

```bash
gh api repos/msieurthenardier/mission-control/issues/{N} --jq '{state, state_reason, title}'
```

(`gh issue view --json` has no `stateReason` field; the REST route does.)

Write the refreshed status back to the artifact:

| Upstream | Status |
|----------|--------|
| `open` | unchanged |
| `closed`, `state_reason: completed` | `accepted` |
| `closed`, `state_reason: not_planned` | `declined` |
| Issue now redirects to another, or its title says it was split | `superseded`, recording the new number |

Records with no issue number — `draft` and `withheld` — are never dereferenced. Report `draft` records separately and ask whether the operator filed them by hand; an unanswered `draft` is a report that silently never left.

Call out anything upstream has fixed. That is usually a cue to run `/mission-control:preflight-check`.

## Guidelines

### Trends, not events

The threshold is the whole design. A methodology defect worth a maintainer's attention is one that kept happening to a working operator across missions — not one that happened once on a hard afternoon. Debriefs already capture the events; this skill's only job is to tell which of them turned out to be patterns.

That is why nothing invokes this skill automatically. Anything that runs it on a fixed cadence tied to the work — per flight, per mission, per release — reintroduces the granularity the threshold exists to filter.

### Joining beats filing — but only on the same root cause

New issues are the exception, and a trend this project already reported is usually a comment, not a second issue. The exception matters just as much: the failure mode of a join-biased design is a handful of magnet issues carrying eighty comments across four unrelated defects, unsplittable without reading all eighty. Run the root-cause test every time, and file new when it says new.

### Vanity is the failure mode

The gate's second criterion exists because subjective preference is the easiest thing to generate and the least useful thing to receive. An observed cost is the price of admission, and across a trend that cost is cumulative and countable. A report with no cost is an opinion, and opinions do not converge.

### Terse is a kindness

The maintainer reads every one of these. Under 200 words, plain words, no preamble. A trend spanning twenty occurrences still gets 200 words; the count does the arguing.

### One report, one trend

Two patterns are two reports even when the same sweep found them. A merged report cannot be individually confirmed, closed, or counted — and a cluster that needed merging to look significant was two events, not one trend.

## Output

Deliverable: the service report artifact(s), persisted per `ARTIFACTS.md`, plus a sweep summary.

Report: the span covered, every cluster found with its occurrence count, the threshold decision for each, the gate outcome and root-cause test for those that proceeded, what was sent (new issue / comment / reaction / nothing), and the upstream links.
