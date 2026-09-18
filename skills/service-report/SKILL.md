---
name: service-report
description: Report a Flight Control methodology difficulty upstream as a GitHub issue on the mission-control repository. Use after a mission debrief surfaces friction with the methodology itself rather than with the project. Searches existing issues first and joins one where the root cause matches, generalizes the report until no project information remains, and sends nothing without explicit operator approval of the exact text.
---

# Service Report

In aviation a **squawk** records a defect in *this* aircraft, cleared by *this* operator. A **service difficulty report** runs the other way: the operator tells the manufacturer the type design has a problem, because every other operator will hit it too.

A service report is Flight Control's channel back to the plugin. It carries one methodology difficulty, generalized until nothing about the project remains, to `msieurthenardier/mission-control`.

**Two rules override everything else here:**

1. **Nothing leaves the project until the operator approves it.** That covers every outbound act: the search query, the issue body, a comment, a reaction. No summary approval, no batch approval, no unattended path.
2. **If it cannot be said without project information, it cannot be filed.** There is no workaround.

## When to Use

After `/mission-control:mission-debrief`. That is the reporting point. A mission's worth of flights is the smallest sample that separates a real methodology defect from one bad afternoon.

Flight debriefs do not report. They record methodology observations in their skill-effectiveness analysis; the mission debrief reads them and counts recurrence. "Hit in 3 of 5 flights" is the difference between something a maintainer can act on and an anecdote.

## Prerequisites

- `.flightops/ARTIFACTS.md` exists with service report conventions — run `/mission-control:init-project` to apply migration 009 if missing
- **Upstream reporting is affirmatively enabled for this project.** Read `ARTIFACTS.md` and find the project's setting for whether methodology findings may be reported upstream. If you cannot determine that it is affirmatively enabled — the setting is absent, unset, ambiguous, or the project uses an artifact backend that does not carry it — **stop** and ask the operator to set it. Do not infer consent from silence. This gate fails closed by design: some organizations forbid posting anything to public repositories, and the cost of asking is one question
- `gh` authenticated. Without it, everything up to submission still runs and the operator gets the finished text plus a link to paste

## Invocation

```
/mission-control:service-report                 Work through the latest mission debrief's methodology findings
/mission-control:service-report {description}   One ad-hoc report
/mission-control:service-report list            Local report log with upstream status
```

## Qualification Gate

A finding is reportable only if **all five** hold:

1. **Reproduces from the methodology alone** — an operator on a different stack, language, and domain would hit it
2. **Has an observed cost** — rework, a re-run, a wrong artifact, a missed gate. Not "would be nicer if"
3. **Not already fixed upstream** — check the installed plugin version against upstream main and closed issues
4. **Not project-owned surface** — not something `ARTIFACTS.md` or the crew files are meant to own. Those are customizable by design; friction there is a local edit
5. **Statable with zero project information**

Say out loud which criterion a rejected finding failed, and where it goes instead:

| Failed | Goes to |
|--------|---------|
| 1 | Stays a project lesson in the debrief |
| 2 | Stays a project lesson in the debrief |
| 3 | `/mission-control:preflight-check`, then `/mission-control:init-project` |
| 4 | A local edit to `ARTIFACTS.md` or the crew file |
| 5 | Nowhere. It cannot be filed |

Criteria 3 and 4 reject more than expected. Most "the methodology is broken" turns out to be drift or local customization.

## Pipeline

Both entry paths converge here. Run it per finding.

### 1. Gather

From the mission debrief: its methodology findings, plus the flight debriefs it already read, for the recurrence count (`{N} of {M} flights`).

From an ad-hoc description: ask at most two questions — what happened, and what it cost. Then ask a third: **has this happened before?** An ad-hoc report has no mission sample behind it. If the operator cannot point to recurrence, the report still goes, but its occurrence line reads `1 observation, unsampled` and the local artifact records that it was raised outside a debrief. Unsampled reports are weaker evidence and should say so rather than pass as mission-level findings.

Record the installed plugin version from `${SKILL_DIR}/../../.claude-plugin/plugin.json`, and the skill and phase where the difficulty showed up.

### 2. Gate

Apply the five criteria. Drop what fails, with the reason.

### 3. Build the deny-list

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

Keep it for steps 4 and 6.

### 4. Generalize

**Write the observation from scratch in methodology vocabulary. Never copy debrief prose and scrub it** — that is how leaks survive.

Methodology terms (`leg`, `flight`, `acceptance criteria`, skill and artifact names) are the shared vocabulary and belong in the report. Project terms do not. The test: *the report must be reconstructible from the methodology alone.* If a reader needs to know what the project does, it is not ready.

Be specific without being proprietary. "A leg whose acceptance criteria named an interface the flight had not specified" is specific. "Leg 03 of the billing-sync flight" is proprietary. "The leg specs were unclear" is neither.

### 5. Search before drafting — with the query approved first

A search query is an outbound request. GitHub receives it, it is attributable to the operator's account, and it lands in their search history. It is covered by rule 1 like everything else.

**Build the query from a closed vocabulary only**: skill names, artifact names, lifecycle state values, signal names, and phase names — all enumerable from the plugin itself. No project terms, no free text lifted from the finding. Run the query against the deny-list from step 3. Then show the operator the literal query strings and get a yes before running anything.

On approval, search in this order:

1. **The project's own service report artifacts**, at the location `ARTIFACTS.md` defines. Cheapest, and catches "we raised this last mission"
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
| **Variant** — same root cause, different manifestation | React `+1`, then comment the occurrence. Do not open a new issue |
| **Duplicate** — same root cause, nothing new to add | React `+1`. No comment |
| **Already fixed** | Not an issue. Route to `/mission-control:preflight-check` |

**Apply the root-cause test, out loud, before choosing variant or duplicate over new:**

> Would **one change to the methodology** fix both this occurrence and the existing issue?

Yes → variant or duplicate. No → **new**, even though new is the exception. Joining is the default, not the answer. Two distinct defects filed under one issue cannot be separated afterwards without hand-reading every comment on it, and the operator who could tell them apart is gone by then. Superficial similarity — same skill, same phase, same words — is not root-cause identity.

### 6. Redaction review

Two checks, in this order. The first is mechanical and authoritative; the second is judgment.

**6a. Deny-list match.** Case-insensitive substring search of every filtered deny-list token against the draft body, the title, and the query strings. **Any hit is a hard fail** — return to step 4 and rewrite. Do not "fix" a hit by deleting the word; a draft that contained the project's name was written from the wrong material.

**6b. Reviewer pass.** Spawn a Redaction Reviewer (Task tool, `subagent_type: "general-purpose"`). Instruct it directly — there is no crew file for this, and none should be added.

Be honest about what this reviewer is and is not. **It is not context-free.** A spawned agent inherits the project's `CLAUDE.md`, which in most projects names the project, its domain, and its stack. It therefore cannot judge "would an outsider recognise this project?" — it already knows the answer and will read a generalized phrase as obviously generic because it knows the referent. That failure mode is why 6a exists and runs first.

What it *can* do is catch what a deny-list cannot: phrasing that only makes sense to someone who knows the project. Ask it exactly that:

- Give it the draft text, the deny-list, and nothing else. Tell it not to read project files
- Its question: **which sentences here would be unintelligible, or would raise a "what are they talking about?", for a reader who knows only the Flight Control methodology?** Those sentences are carrying project context implicitly
- Have it also check the explicit classes: usernames or home paths; repo, org, or product names; customer or partner names; internal hostnames or URLs; credentials, keys, tokens; project file paths; project code; artifact excerpts; stack traces; ticket ids; domain vocabulary
- It returns `[CLEAR]`, or the specific spans that fail and why

Any failure goes back to step 4 for a rewrite, not a patch.

### 7. Draft

**New issue.** Title ≤ 80 characters, stating the difficulty, not the fix. Body:

```markdown
### What happened
One sentence.

### What was expected
One sentence.

### Cost
What it cost — rework, a re-run, a wrong artifact, a missed gate.

### Repro
Two or three lines. Generic, minimal, in methodology terms.

---
Plugin: {version}
Skill: {skill name}
Phase: {phase name, or —}
Occurrences: {N} of {M} flights in one mission
```

**Variant comment.** Shorter, same trailer:

```markdown
### Another occurrence
- Matches the report: {what is the same}
- Differs: {the one dimension that differs}
- Cost: {one line}

---
Plugin: {version}
Skill: {skill name}
Phase: {phase name, or —}
Occurrences: {N} of {M} flights in one mission
```

That trailer is fixed-format on purpose. It is the only thing that makes a corpus of reports countable — which skill, which phase, which version, how often — and it has to appear identically on issues and comments alike or there is nothing to aggregate.

The `Differs` line is the point of the comment. Each occurrence either matches the issue exactly or names the one dimension it varies on. That tightens an issue's scope as reports accumulate instead of scattering it across near-duplicates — and when the `Differs` lines on an issue stop clustering, that is the signal the issue is carrying more than one defect and should be split.

**Style, enforced:**

- Terse. Whole body under 200 words
- Plain words. No throat-clearing, no framing, no gratitude
- **Report the difficulty, not the redesign.** No proposed solution section. Operators report difficulties; the maintainer designs the fix. At most one line of `Suggested direction:` and only if the operator asks for it
- No quality adjectives — "confusing", "clunky", "awkward" — without the observable that produced them
- If two operators could not recognise the same thing from the text, it is not specific enough yet

### 8. Approve

Show the operator the exact text that will be sent, verbatim, not summarized — and name the act. Per branch:

| Branch | Show |
|--------|------|
| **New issue** | Repository, title, full body |
| **Variant** | Repository, issue #N and its title, the full comment body, and that a 👍 reaction goes with it |
| **Duplicate** | Repository, issue #N and its title, and that this posts a 👍 reaction — no text |
| **Already fixed** | Nothing is sent. Say so and route onward |

State plainly: **this posts publicly, under your GitHub account.** A reaction is a public, attributable act and gets the same question as an issue body; it is not exempt for being small.

Then ask. Send, edit, or withhold.

**Stop at `draft` if you cannot put this question to a person and get an answer before continuing** — a spawned agent, a scripted or scheduled run, any session with no human present. Being invoked through `/mission-control:mission-debrief`'s handoff is *not* that case: the operator is there, they simply arrived via another skill. The test is whether a human answers, not which skill called.

### 9. Submit

Write the approved body to a scratch file outside the project tree (`mktemp`), submit, then delete it:

```bash
# New
gh issue create --repo msieurthenardier/mission-control \
  --title "{title}" --body-file {scratch}

# Variant — react, then comment
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
gh issue comment {N} --repo msieurthenardier/mission-control --body-file {scratch}

# Duplicate — react only
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
```

No `--label`: label names are resolved against the repository and a missing one fails the create outright. Labelling is the maintainer's triage step.

**On failure — auth expired, rate limit, a 404 on the issue number, a network error — stop and report it to the operator.** If they ask to retry, retry with **the approved bytes verbatim**. Never re-draft, re-word, or trim a body to make a submission succeed: the operator approved specific text, and anything else posting under their account is a rule 1 violation arriving through the back door.

No `gh` at all: hand the operator the body and `https://github.com/msieurthenardier/mission-control/issues/new`. Record the report as `draft` — it is not submitted until they say it was.

### 10. Record

Write the artifact per `.flightops/ARTIFACTS.md`, including the submitted text **verbatim**. The artifact is the local audit trail of exactly what left the project. It may reference local debrief paths; nothing sent upstream ever does.

Set status by branch:

| Branch | Status |
|--------|--------|
| New issue created | `submitted` |
| Variant — reaction + comment | `merged` |
| Duplicate — reaction only | `merged` |
| Operator declined to send | `withheld` |
| No `gh`, text handed over | `draft` |
| Gate or redaction failure, abandoned | `withheld`, with the reason |

## Verb: list

Check the project's upstream reporting setting first, exactly as the prerequisites describe. A project that has opted out does not get outbound calls from this verb either.

Read the service report artifacts at the location `ARTIFACTS.md` defines. Report id, title, status, upstream link, and age.

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

### Joining beats filing — but only on the same root cause

New issues are the exception. A skill that opens one per mission per project produces a tracker nobody can read.

The exception matters just as much. The failure mode of a join-biased design is a handful of magnet issues carrying eighty comments across four unrelated defects, unsplittable without reading all eighty. Run the root-cause test every time, and file new when it says new.

### Vanity is the failure mode

The gate's second criterion exists because subjective preference is the easiest thing to generate and the least useful thing to receive. An observed cost is the price of admission. A report with no cost is an opinion, and opinions do not converge.

### Terse is a kindness

The maintainer reads every one of these. Under 200 words, plain words, no preamble.

### One report, one difficulty

Two frictions are two reports even when found in the same debrief. A merged report cannot be individually confirmed, closed, or counted.

## Output

Deliverable: the service report artifact(s), persisted per `ARTIFACTS.md`.

Report per finding: the gate outcome, the search classification and the root-cause test that justified it, what was sent (new issue / comment / reaction / nothing), and the upstream link.
