---
name: service-report
description: Sweep this project's accumulated debriefs for recurring Flight Control methodology trends and report them upstream as GitHub issues on the mission-control repository. Operator-invoked whenever they choose, typically after several missions. Clusters observations across debriefs into trends, searches existing issues first and joins one where the root cause matches, generalizes until no project information remains, and sends nothing without explicit approval of the exact text.
---

# Service Report

In aviation a **squawk** records a defect in *this* aircraft, cleared by *this* operator. A **service difficulty report** runs the other way: the operator tells the manufacturer the type design has a problem, because every other operator will hit it too. Manufacturers act on the pattern across the fleet, not on the first report.

A service report carries one recurring Flight Control methodology **trend** to `msieurthenardier/mission-control`, generalized until nothing about the project remains.

**Two rules override everything else here:**

1. **Nothing that carries content leaves the project until the operator approves it.** The issue body, a comment, a reaction, and the search query — every act that transmits something the project produced. The line is drawn on **content, not on HTTP method**: a search query is a read and is still covered, because the terms are content. Fetching the status of an issue this project already filed transmits nothing and is exempt; the project-level opt-out switch is what protects a project that must make no calls at all.
2. **If it cannot be said without project information, it cannot be filed.** There is no workaround.

## When to Use

**Whenever the operator chooses.** This skill is not attached to any debrief, any phase gate, or any schedule. Nothing invokes it and no skill hands off to it. `/mission-control:routine-maintenance` may *mention* that a corpus has accumulated; a mention is not a trigger.

In practice that means after several missions, when there is enough accumulated material for patterns to be visible. Debriefs are the instrument; this is the periodic read of what they recorded. Running it after every mission produces events, not trends — and events are what floods a tracker.

A sweep re-reads the whole corpus every time, by design. A pattern that sat below the threshold six months ago may have crossed it since. **The second sweep is the normal case, not the first** — step 1 exists because of it, and every classification below has to hold when the same clusters come back around.

## Prerequisites

- `.flightops/ARTIFACTS.md` exists with service report conventions — run `/mission-control:init-project` to apply migration 009 if missing
- **Upstream reporting is affirmatively enabled for this project.** Read `ARTIFACTS.md` and find the project's setting for whether methodology findings may be reported upstream. If you cannot determine that it is affirmatively enabled — the setting is absent, unset, ambiguous, or the project uses an artifact backend that does not carry it — **stop** and ask the operator to set it. Do not infer consent from silence. This gate fails closed by design: some organizations forbid posting anything to public repositories, and the cost of asking is one question
- Enough corpus to sweep. One mission's worth of debriefs cannot show a trend; say so and stop rather than reporting events
- `gh` authenticated. Without it, everything up to submission still runs and the operator gets the finished text plus a link to paste

## Invocation

```
/mission-control:service-report                 Sweep the corpus for recurring methodology trends
/mission-control:service-report {hypothesis}    Sweep, focused on one suspected trend
/mission-control:service-report list            This project's service reports, with upstream status
```

The `{hypothesis}` form is **not** a report to file. It is the operator saying "I think this keeps happening" — the sweep then goes looking for corroboration in the corpus, and reports what the evidence supports, including "the debriefs do not bear this out." A hunch with no record behind it is not a trend, and filing one would be the exact failure this skill exists to avoid. If the hypothesis is corroborated but sits below the threshold, it goes to the override checkpoint in step 4 like any other sub-threshold cluster.

## Pipeline

### 1. Read this project's prior service reports — first

Before reading any debrief, read the service report artifacts at the location `ARTIFACTS.md` defines. Each one records a trend, the observations behind it (its `Evidence`), and what became of it upstream.

This comes first for two reasons. It is what stops a re-sweep re-filing what the last sweep filed. And **the recorded clusters seed step 3**: observations already assigned to a known trend stay assigned, so cluster boundaries survive between sweeps instead of being re-derived from scratch and then fuzzily matched. Re-deriving boundaries every run is the single largest source of run-to-run variance in a skill whose output is meant to be stable.

Note each prior report's status; step 8 needs it.

### 2. Survey the corpus

Record the **installed plugin version** now, from `${SKILL_DIR}/../../.claude-plugin/plugin.json`. It stamps this sweep and backstops observations that carry no version of their own.

Read every artifact in this project that records how the methodology behaved. Locate them per `ARTIFACTS.md`:

- **Mission debriefs** — methodology feedback, process analysis, lessons learned
- **Flight debriefs** — skill-effectiveness analysis, what could be improved, deviations
- **Maintenance reports** — findings attributed to process rather than code
- **Escalated squawks** — a squawk that failed its qualification gate often marks a place where the methodology mis-sorted the work

**Do this in two passes.** A mature corpus does not fit in one context, and a partial read fails silently and directionally: it undercounts, the threshold is a count, and an undercount reads as "no trend here."

1. **Extract.** Artifact by artifact, reduce each to its methodology observations, written to a working file **outside the project tree** (`mktemp -d`). Per observation: what the methodology did, what was expected, what it cost, the skill and phase, the flight and mission it belongs to, the date, and the plugin version if the artifact records one. Frame the extraction by intent — what you are looking for — rather than by section heading; project-owned artifacts do not owe you a fixed structure.
2. **Cluster over the extracts only**, never over the original artifacts.

Count **artifacts found** against **artifacts read**. If they differ, say so plainly. **Do not make a threshold decision on an incomplete sweep** unless the operator is told the coverage and accepts it explicitly — a filing based on a partial corpus is a confidently quantified guess.

Report the span covered: how many missions, how many flights, what date range.

### 3. Cluster into candidate trends

Start from the clusters recovered in step 1 — assign matching observations to the trend they already belong to. Then cluster what remains.

This is the substance of the sweep, and the part that cannot be done by matching words. Debriefs written months apart describe the same friction in different language, by different agents, at different levels of detail. **Cluster on what the methodology did, not on how it was worded.** Two rules keep clusters honest:

- **Do not cluster on the skill name alone.** Two unrelated defects in `flight-debrief` are two trends, not one "flight-debrief is awkward" trend. That collapse is the single most common way a sweep produces something unactionable.
- **Apply the root-cause test to every cluster**: would **one change to the methodology** remove every observation in it? If not, split it.

For each cluster record: its observations, the flights and missions they span, the date range, the plugin versions involved, and the aggregate cost.

### 4. Apply the trend threshold

A cluster is a trend when it has **at least three independent observations spanning at least two missions**.

**An independent observation is one distinct underlying occurrence** — a single time the methodology did the thing, attributed to the flight it happened in. It is *not* one artifact mentioning it. This matters because the corpus double-reports by construction: a mission debrief's methodology feedback is derived from its flight debriefs, so the same occurrence appears in both. **That is one observation, not two.** Count occurrences, never documents.

Maintenance reports and escalated squawks are **corroborating only**. They strengthen a trend's description and its cost, and they do not count toward the three — a squawk has no parent flight or mission, and a maintenance report sits between missions, so neither can be placed in the span the threshold measures.

Below the threshold, a cluster is an event. Leave it in the corpus and say so — the next sweep will pick it up if it keeps happening.

**Override checkpoint.** Before continuing, present every sub-threshold cluster to the operator, ranked by observation count, and ask once whether any should proceed anyway. This is the only moment an override is possible; surfacing them in the closing report instead would tell the operator what they might have overridden after everything else was already filed. Anything they promote carries `below threshold` in its occurrence line, and the local artifact records the override.

### 5. Gate

Each trend is reportable only if **all five** hold:

1. **Reproduces from the methodology alone** — an operator on a different stack, language, and domain would hit it
2. **Has an observed cost** — rework, a re-run, a wrong artifact, a missed gate, accumulated across occurrences. Not "would be nicer if"
3. **Not already fixed upstream** — *deferred*. This cannot be answered here: it needs an upstream query, and no query may run before the deny-list exists (step 6) and the operator has approved the terms (step 8). Mark it provisionally passed and resolve it at step 8, where a hit routes the trend to `/mission-control:preflight-check` instead of an issue
4. **Not project-owned surface** — not something `ARTIFACTS.md` or the crew files are meant to own. Those are customizable by design; friction there is a local edit, and a trend confined to them is proof the edit is worth making
5. **Statable with zero project information**

Say out loud which criterion a rejected trend failed, and where it goes instead:

| Failed | Goes to |
|--------|---------|
| 1 | Stays a project lesson |
| 2 | Stays a project lesson |
| 3 (at step 8) | `/mission-control:preflight-check`, then `/mission-control:init-project` |
| 4 | A local edit to `ARTIFACTS.md` or the crew file |
| 5 | Nowhere. It cannot be filed |

Criteria 3 and 4 reject more than expected. Most "the methodology is broken" turns out to be drift or local customization, and a sweep is the best chance to notice which.

### 6. Build the deny-list

Before any text is drafted, collect the strings that must never appear in anything sent upstream.

**Be precise about what this control covers.** It is mechanical and it is the only deterministic check in the pipeline — but it catches identifiers it can enumerate or pattern-match, and nothing else. Project *phrasing* is not in its reach; that is step 10b's job, with the limits stated there.

**Tokens** — emit one per line, stripped of punctuation and path decoration:

```bash
git remote -v | sed -E 's#.*[:/]([^/]+)/([^ ]+)\.git.*#\1\n\2#' | sort -u   # owner, repo
git remote -v | sed -E 's#.*@([^:/]+).*#\1#' | sort -u                      # host
basename "$PWD"                                                             # project directory
git log --format='%an%n%ae' | sort -u                                       # every contributor
git config user.name; git config user.email
ls -d */ 2>/dev/null | tr -d '/'                                            # directory names, no slash
echo "$HOME"
```

Add the package manifest's project name where one exists (`package.json` `name`, `pyproject.toml` `name`, `Cargo.toml` `name`, `go.mod` module path).

**Filter the tokens** before using them: drop anything under four characters, and drop generic directory names that would match innocent prose — `src`, `lib`, `app`, `api`, `bin`, `cmd`, `pkg`, `test`, `tests`, `docs`, `build`, `dist`, `internal`, `vendor`, `node_modules`. A deny-list that fires on every draft gets ignored, which is worse than no deny-list.

**Patterns** — these catch the high-consequence classes no token list can enumerate, and they run on the draft regardless of what the project is called:

| Class | Pattern |
|-------|---------|
| Ticket ids | `[A-Z]{2,}-[0-9]+` |
| Email addresses | `[^ ]+@[^ ]+\.[a-z]{2,}` |
| URLs and hostnames | `https?://`, `[a-z0-9-]+\.(internal\|local\|corp\|lan)\b` |
| IP addresses | `\b([0-9]{1,3}\.){3}[0-9]{1,3}\b` |
| Absolute paths | `(/home/\|/Users/\|C:\\\\Users\\\\)` |
| Probable secrets | long unbroken high-entropy strings; `(api[_-]?key\|secret\|token\|password\|bearer)` near a value |

Keep the tokens and the patterns for steps 7, 8, 9 and 10a.

### 7. Generalize

**Write the trend from scratch in methodology vocabulary. Never copy debrief prose and scrub it** — that is how leaks survive. The corpus is written in the project's own language throughout, so this step matters more here than anywhere else in Flight Control.

Methodology terms (`leg`, `flight`, `acceptance criteria`, skill and artifact names) are the shared vocabulary and belong in the report. Project terms do not. The test: *the report must be reconstructible from the methodology alone.* If a reader needs to know what the project does, it is not ready.

Watch for the project's own **domain nouns** — the words its `README.md` title and `CLAUDE.md` opening use for what it builds. They are the likeliest leak and the hardest to notice, because to you they read as ordinary English. A deny-list cannot catch them reliably; write around them deliberately.

Be specific without being proprietary. "A leg whose acceptance criteria named an interface the flight had not specified" is specific. "Leg 03 of the billing-sync flight" is proprietary. "The leg specs were unclear" is neither.

Describe the **pattern**, then one generic instance of it. Not five instances — one, chosen because it is the clearest, with the count carrying the weight the other four would have.

### 8. Search before drafting — with the query approved first

A search query transmits content: the terms are chosen by this project, from this project's corpus. It is covered by rule 1, and that it is a read does not exempt it.

**Build the query from a closed vocabulary only**: skill names, artifact names, lifecycle state values, phase names, and the **default** signal names read from `${SKILL_DIR}/../init-project/defaults/agent-crews/`. Read them from the plugin, never from the project's own `.flightops/` — crew files and `ARTIFACTS.md` are project-owned and freely renamed, so a project's signal or artifact names are project vocabulary, not shared vocabulary. Run the query against the deny-list tokens and patterns from step 6. Then show the operator the literal query strings and get a yes before running anything.

On approval, search in this order:

1. **Upstream open issues**, then **closed issues separately** — closed issues resolve the deferred gate criterion 3, and sharing one result budget with open issues buries them:
   ```bash
   gh issue list --repo msieurthenardier/mission-control --state open   --search "{terms}" --limit 60
   gh issue list --repo msieurthenardier/mission-control --state closed --search "{terms}" --limit 60
   ```
2. **Open PRs and recent commits**, for a fix already in flight:
   ```bash
   gh pr list --repo msieurthenardier/mission-control --state open --search "{terms}" --limit 30
   gh api repos/msieurthenardier/mission-control/commits --jq '.[].commit.message' | head -50
   ```

Classify into exactly one, checking the prior reports from step 1 before the upstream results:

| Outcome | Action |
|---------|--------|
| **Already reported, unchanged** — a prior report covers this trend and no new observations have accumulated | **Nothing is sent.** Note it in the sweep summary and move on. Do not react, do not comment |
| **Recurred** — a prior `submitted`/`merged` report covers it and new observations have accumulated since | React `+1`, then comment the updated count and span. This is the most valuable comment the skill produces |
| **Prior report `withheld`** — the operator previously declined to send this | Treat as **New**, but tell the operator it was declined before, when, and why, *before* drafting. A standing refusal deserves to be remembered, not silently re-litigated |
| **Prior report `declined` upstream** — the maintainer closed it `not_planned` | **Do not re-file.** Raise it with the operator only if the observation count has materially grown, and say plainly that the maintainer declined it and when |
| **New** | Draft an issue |
| **Variant** — same root cause, different manifestation, someone else's issue | React `+1`, then comment the occurrence |
| **Duplicate** — someone else's issue, same root cause, nothing to add | React `+1`. No comment |
| **Already fixed** — resolves deferred criterion 3 | Not an issue. Route to `/mission-control:preflight-check` |

**Apply the root-cause test, out loud, before choosing anything other than new:**

> Would **one change to the methodology** fix both this trend and the existing issue?

Yes → recurred, variant, or duplicate. No → **new**, even though new is the exception. Joining is the default, not the answer. Two distinct defects filed under one issue cannot be separated afterwards without hand-reading every comment on it, and the operator who could tell them apart is gone by then. Superficial similarity — same skill, same phase, same words — is not root-cause identity.

### 9. Draft

**New issue.** Title ≤ 80 characters, prefixed `[methodology] `, stating the difficulty not the fix. Body:

```markdown
### What happens
One sentence describing the pattern.

### What was expected
One sentence.

### Cost
What it has cost across occurrences — rework, re-runs, wrong artifacts, missed gates.

### Repro
Two or three lines. One generic instance, minimal, in methodology terms.

### Plugin
{versions spanned, e.g. 0.9.2–1.0.1}

### Skill
{skill name}

### Phase
{phase name, or —}

### Occurrences
{N} occurrences across {M} missions

### Span
{YYYY-MM} to {YYYY-MM}
```

**Recurred / variant comment.** Shorter, same five trailing sections:

```markdown
### Continued occurrence
- Matches the report: {what is the same}
- Differs: {the one dimension that differs, or "nothing new — count only"}
- Since last reported: {what has accumulated}
```

Those five sections are fixed-format on purpose, and they are the exact field labels the repository's issue form produces — so a swept report and a hand-filed one aggregate as one shape. They are the only thing that makes a corpus of reports countable: which skill, which phase, which versions, how often, over how long. **Span and version range are the trend evidence**: "still happening eight months and two releases later" is the claim a maintainer can act on.

If the corpus predates version stamping, write `unrecorded before {installed version}` rather than inventing a range. An honest gap beats a fabricated span.

The `Differs` line is the point of the comment. Each occurrence either matches the issue exactly or names the one dimension it varies on. That tightens an issue's scope as reports accumulate instead of scattering it across near-duplicates — and when the `Differs` lines on an issue stop clustering, that is the signal the issue is carrying more than one defect and should be split.

**Style, enforced:**

- Terse. Whole body under 200 words, however large the trend
- Plain words. No throat-clearing, no framing, no gratitude
- **Report the difficulty, not the redesign.** No proposed solution section. Operators report difficulties; the maintainer designs the fix. At most one line of `Suggested direction:` and only if the operator asks for it
- No quality adjectives — "confusing", "clunky", "awkward" — without the observable that produced them
- Counts, not anecdotes. The evidence is that it kept happening; one instance illustrates, it does not argue
- If two operators could not recognise the same thing from the text, it is not specific enough yet

### 10. Redaction review

Two checks, in this order. The first is mechanical and authoritative within its reach; the second is judgment, with known limits.

**10a. Deny-list match.** Run every filtered token (case-insensitive substring) and every pattern from step 6 against the draft body, the title, and the query strings. **Any hit is a hard fail** — return to step 7 and rewrite. Do not "fix" a hit by deleting the word; a draft that contained the project's name was written from the wrong material.

**10b. Reviewer pass.** Spawn a Redaction Reviewer (Task tool, `subagent_type: "general-purpose"`). Instruct it directly — there is no crew file for this, and none should be added.

Be honest about what this reviewer is and is not. **It is not context-free.** A spawned agent inherits the project's `CLAUDE.md`, which in most projects names the project, its domain, and its stack. It therefore cannot judge "would an outsider recognise this project?" — it already knows the answer and will read a generalized phrase as obviously generic because it knows the referent. That failure mode is why 10a exists and runs first.

What it *can* do is catch what tokens and patterns cannot: phrasing that only makes sense to someone who knows the project. Ask it exactly that:

- Give it the draft text and nothing else. **Do not hand it the deny-list** — that list contains the operator's name, email, and home path, and 10a has already matched them. Pass only the pattern classes to look for, never the operator's identity
- Constrain it plainly: **it must not run commands, fetch URLs, or read any file.** It receives text and returns text
- Its question: **which sentences here would be unintelligible, or would raise a "what are they talking about?", for a reader who knows only the Flight Control methodology?** Those sentences are carrying project context implicitly
- Have it also check the classes 10a cannot enumerate: customer or partner names, product names, internal system names, domain vocabulary, artifact excerpts, stack traces, project code
- It returns `[CLEAR]`, or the specific spans that fail and why

Any failure goes back to step 7 for a rewrite, not a patch.

### 11. Approve

Show the operator the exact text that will be sent, verbatim, not summarized — and name the act. Per branch:

| Branch | Show |
|--------|------|
| **New issue** | Repository, title, full body |
| **Recurred / Variant** | Repository, issue #N and its title, the full comment body, and that a 👍 reaction goes with it |
| **Duplicate** | Repository, issue #N and its title, and that this posts a 👍 reaction — no text |
| **Already reported unchanged / Already fixed** | Nothing is sent. Say so and move on |

State plainly: **this posts publicly, under your GitHub account.** A reaction is a public, attributable act and gets the same question as an issue body; it is not exempt for being small.

A sweep may surface several trends at once. **Approve them one at a time.** The operator sees each body and answers for it; there is no "yes to all", because a batch approval is an approval of a summary, and rule 1 is about exact text.

Then ask. Send, edit, or withhold.

**Stop at `draft` if you cannot put this question to a person and get an answer before continuing** — a spawned agent, a scripted or scheduled run, any session with no human present. This skill is operator-invoked by design, so that situation should not arise; if it does, something has gone wrong upstream of here.

### 12. Submit

Write the approved body to a scratch file outside the project tree (`mktemp`), submit, then delete it:

```bash
# New
gh issue create --repo msieurthenardier/mission-control \
  --title "[methodology] {title}" --body-file {scratch}

# Recurred / Variant — react, then comment
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
gh issue comment {N} --repo msieurthenardier/mission-control --body-file {scratch}

# Duplicate — react only
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
```

No `--label`: label names are resolved against the repository and a missing one fails the create outright. Labelling is the maintainer's triage step.

**On failure — auth expired, rate limit, a 404 on the issue number, a network error — stop and report it to the operator.** If they ask to retry, retry with **the approved bytes verbatim**. Never re-draft, re-word, or trim a body to make a submission succeed: the operator approved specific text, and anything else posting under their account is a rule 1 violation arriving through the back door. **Delete the scratch file once the operator abandons the attempt**, not only on success — an approved body should not outlive the decision to send it.

No `gh` at all: hand the operator the body and `https://github.com/msieurthenardier/mission-control/issues/new`. Record the report as `draft` — it is not submitted until they say it was.

### 13. Record

Write the artifact per `.flightops/ARTIFACTS.md`, including the submitted text **verbatim**. The artifact is the local audit trail of exactly what left the project, and the seed the next sweep reads in step 1.

Record the supporting observations — which debriefs, flights, and missions the trend was drawn from. Those are local references and **never appear in anything sent upstream**.

Set status by branch:

| Branch | Status |
|--------|--------|
| New issue created | `submitted` |
| Recurred / variant — reaction + comment | `merged` |
| Duplicate — reaction only | `merged` |
| Operator declined to send | `withheld`, with the reason and date |
| Gate or redaction failure, abandoned | `withheld`, with the reason |
| No `gh`, text handed over | `draft` |
| No human present, stopped at step 11 | `draft` |
| Already reported unchanged | No new artifact. Note the sweep date on the existing one |

Close the sweep by reporting: the span covered, artifacts read against artifacts found, the clusters found, which crossed the threshold, which were overridden, which were filed or joined, which were already reported unchanged, and which were left in the corpus to see whether they keep happening.

## Verb: list

Check the project's upstream reporting setting first, exactly as the prerequisites describe. A project that has opted out makes no calls from this verb either.

Read the service report artifacts at the location `ARTIFACTS.md` defines. Report id, title, status, upstream link, the trend's occurrence count and span at time of filing, and age.

For any record carrying an issue number — `submitted` or `merged` — refresh upstream state. This transmits nothing the project produced, so it needs no per-call approval under rule 1:

```bash
gh api repos/msieurthenardier/mission-control/issues/{N} --jq '{number, state, state_reason, title, html_url, pull_request}'
```

(`gh issue view --json` has no `stateReason` field; the REST route does. Project `number` and `html_url` so a transfer is visible, and `pull_request` because this route also serves PRs — if that key is present the recorded number is not an issue, and the record is wrong rather than closed.)

Write the refreshed status back to the artifact:

| Upstream | Status |
|----------|--------|
| `open` | unchanged |
| `closed`, `state_reason: completed` | `accepted` |
| `closed`, `state_reason: not_planned` | `declined` |
| `closed`, `state_reason` null or absent | `accepted`, noted as inferred — usually closed by a merged PR |
| Returned `number` differs from the recorded one, or a previously reachable issue now 404s | `superseded`, recording the new number where one is given |

Records with no issue number — `draft` and `withheld` — are never dereferenced. Report `draft` records separately and ask whether the operator filed them by hand; an unanswered `draft` is a report that silently never left. Report `withheld` records too, with their reasons, so a standing refusal stays visible.

Call out anything upstream has fixed. That is usually a cue to run `/mission-control:preflight-check`.

## Guidelines

### Trends, not events

The threshold is the whole design. A methodology defect worth a maintainer's attention is one that kept happening to a working operator across missions — not one that happened once on a hard afternoon. Debriefs already capture the events; this skill's only job is to tell which of them turned out to be patterns.

That is why nothing invokes this skill. Anything that runs it on a fixed cadence tied to the work — per flight, per mission, per release — reintroduces the granularity the threshold exists to filter.

### Count occurrences, never documents

The corpus describes the same occurrence more than once by design: a mission debrief's methodology feedback is derived from its flight debriefs. Counting documents inflates every trend by roughly double and makes two occurrences look like a pattern. Every count in this skill — the threshold, the trailer, a `Recurred` comment's claim of growth — is a count of distinct occurrences.

### The second sweep is where it goes wrong

Re-running is the normal case. That is why prior reports are read first and seed the clustering, why "already reported, unchanged" sends nothing at all, and why a `withheld` or `declined` report is not quietly re-proposed. A sweep that re-derives its clusters from scratch, re-counts inflated numbers, and posts a `Recurred` comment claiming growth that is really double-counting is the worst output this skill can produce — it is wrong, confident, and quantified.

### Joining beats filing — but only on the same root cause

New issues are the exception, and a trend this project already reported is a comment at most. The exception matters just as much: the failure mode of a join-biased design is a handful of magnet issues carrying eighty comments across four unrelated defects, unsplittable without reading all eighty. Run the root-cause test every time, and file new when it says new.

### Vanity is the failure mode

The gate's second criterion exists because subjective preference is the easiest thing to generate and the least useful thing to receive. An observed cost is the price of admission, and across a trend that cost is cumulative and countable. A report with no cost is an opinion, and opinions do not converge.

### Terse is a kindness

The maintainer reads every one of these. Under 200 words, plain words, no preamble. A trend spanning twenty occurrences still gets 200 words; the count does the arguing.

### One report, one trend

Two patterns are two reports even when the same sweep found them. A merged report cannot be individually confirmed, closed, or counted — and a cluster that needed merging to look significant was two events, not one trend.

## Output

Deliverable: the service report artifact(s), persisted per `ARTIFACTS.md`, plus a sweep summary.

Report: the span covered, artifacts read against artifacts found, every cluster with its occurrence count, the threshold decision and any override, the gate outcome and root-cause test for those that proceeded, what was sent (new issue / comment / reaction / nothing), and the upstream links.
