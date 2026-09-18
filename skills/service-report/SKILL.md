---
name: service-report
description: Report a Flight Control methodology difficulty upstream as a GitHub issue on the mission-control repository. Use after a mission debrief surfaces friction with the methodology itself rather than with the project. Searches existing issues first and joins one where it can, generalizes the report until no project information remains, and files only with explicit operator approval of the exact text.
---

# Service Report

In aviation a **squawk** records a defect in *this* aircraft, cleared by *this* operator. A **service difficulty report** runs the other way: the operator tells the manufacturer the type design has a problem, because every other operator will hit it too.

A service report is Flight Control's channel back to the plugin. It carries one methodology difficulty, generalized until nothing about the project remains, to `msieurthenardier/mission-control`.

**Two rules override everything else here:**

1. **Nothing leaves the project until the operator approves the exact text.** No summary approval, no batch approval, no unattended path.
2. **If it cannot be said without project information, it cannot be filed.** There is no workaround.

## When to Use

After `/mission-control:mission-debrief`. That is the reporting point. A mission's worth of flights is the smallest sample that separates a real methodology defect from one bad afternoon.

Flight debriefs do not report. They record methodology observations in their skill-effectiveness analysis; the mission debrief reads them and counts recurrence. "Hit in 3 of 5 flights" is the difference between something a maintainer can act on and an anecdote.

## Prerequisites

- `.flightops/ARTIFACTS.md` exists with a Service Report section — run `/mission-control:init-project` to apply migration 009 if missing
- Upstream reporting is not set to `disabled` in that section. If it is, say so and stop; the project has opted out of sending anything outside the repository
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
2. **Has an observed cost** — rework, a re-run, a wrong artifact, a missed gate, a stall. Not "would be nicer if"
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

From the mission debrief: its methodology findings, plus the flight debriefs it already read, for the recurrence count (`{N} of {M} flights`). From an ad-hoc description: ask at most two questions — what happened, and what it cost.

Record the installed plugin version from `${SKILL_DIR}/../../.claude-plugin/plugin.json`.

### 2. Gate

Apply the five criteria. Drop what fails, with the reason.

### 3. Generalize

**Write the observation from scratch in methodology vocabulary. Never copy debrief prose and scrub it** — that is how leaks survive.

Methodology terms (`leg`, `flight`, `acceptance criteria`, skill and artifact names) are the shared vocabulary and belong in the report. Project terms do not. The test: *the report must be reconstructible from the methodology alone.* If a reader needs to know what the project does, it is not ready.

Be specific without being proprietary. "A leg whose acceptance criteria named an interface the flight had not specified" is specific. "Leg 03 of the billing-sync flight" is proprietary. "The leg specs were unclear" is neither.

### 4. Search before drafting

Filing a new issue is the **last** resort, not the default. In order:

1. **The local log** — reports this project already sent. Cheapest, and catches "we raised this last mission"
2. **Upstream, open and closed:**
   ```bash
   gh search issues --repo msieurthenardier/mission-control --limit 30 "{terms}"
   gh issue list --repo msieurthenardier/mission-control --state all --search "{terms}" --limit 30
   ```
   Search on methodology terms — skill names, artifact names, state names, signal names. Never project terms
3. **Open PRs and recent commits on main**, for a fix already in flight

Classify into exactly one:

| Outcome | Action |
|---------|--------|
| **New** | Draft an issue |
| **Variant** — same root cause, different manifestation | Comment on the existing issue with the occurrence. Do not open a new one |
| **Duplicate** — nothing new to add | React `+1` on the existing issue. No comment. Record locally |
| **Already fixed** | Not an issue. Route to `/mission-control:preflight-check` |

A hundred operators filing separate issues for one defect buries it. The same hundred adding occurrences to one issue specifies it.

### 5. Draft

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

### Occurrences
{N} of {M} flights in one mission. Plugin {version}.
```

**Variant comment.** Shorter:

```markdown
### Another occurrence
- Plugin: {version}
- Skill / phase: {name}
- Matches the report: {what is the same}
- Differs: {the one dimension that differs, or "nothing new"}
- Cost: {one line}
```

That `Differs` line is the point of the whole comment. Each occurrence either matches the issue exactly or names the one dimension it varies on. That tightens an issue's scope as reports accumulate instead of scattering it across near-duplicates.

**Style, enforced:**

- Terse. Whole body under 200 words
- Plain words. No throat-clearing, no framing, no gratitude
- **Report the difficulty, not the redesign.** No proposed solution section. Operators report difficulties; the maintainer designs the fix. At most one line of `Suggested direction:` and only if the operator asks for it
- No quality adjectives — "confusing", "clunky", "awkward" — without the observable that produced them
- If two operators could not recognise the same thing from the text, it is not specific enough yet

### 6. Redaction review

Spawn a Redaction Reviewer (Task tool, `subagent_type: "general-purpose"`). Instruct it directly — there is no crew file for this, and none should be added:

- Give it **only** the draft text. Tell it explicitly not to read project files, and not to ask for context
- Its question is the outsider's: **from this text alone, can you tell what this project is, does, or is called?**
- Checklist: operator username or home paths; repo, org, or product names; customer or partner names; internal hostnames or URLs; credentials, keys, tokens; project file paths; project code; artifact excerpts; stack traces; ticket ids; domain vocabulary
- It returns `[CLEAR]`, or the specific spans that fail and why

Any failure goes back to step 3 for a rewrite, not a patch. Re-review. This separation is the same one the rest of the methodology runs on — Developer/Reviewer, Executor/Validator — applied to disclosure instead of correctness.

### 7. Approve

Show the operator the exact text that will be sent: repository, target (new issue or issue #N), title, labels, and the full body verbatim. Not a summary.

State plainly: **this posts publicly, under your GitHub account.**

Then ask. Send, edit, or withhold.

If the session is non-interactive or running inside another skill's orchestration, stop at `draft` and report. There is no path that submits without a person answering this question.

### 8. Submit

Write the body to a scratch file outside the project tree, then:

```bash
# New
gh issue create --repo msieurthenardier/mission-control \
  --title "{title}" --body-file {scratch} --label methodology

# Variant
gh issue comment {N} --repo msieurthenardier/mission-control --body-file {scratch}

# Duplicate
gh api -X POST repos/msieurthenardier/mission-control/issues/{N}/reactions -f content=+1
```

No `gh`: hand the operator the body and `https://github.com/msieurthenardier/mission-control/issues/new`. Record the report as `draft`.

### 9. Record

Write the artifact per `.flightops/ARTIFACTS.md`, including the submitted body **verbatim** in a fenced block. The artifact is the local audit trail of exactly what left the project. It may reference local debrief paths; the issue body never does.

Set status: `submitted` (new issue), `merged` (joined an existing one), or `withheld`.

## Verb: list

Read the local log. Report id, title, status, upstream link, and age. For anything `submitted` or `merged`, refresh upstream state:

```bash
gh issue view {N} --repo msieurthenardier/mission-control --json state,stateReason,title
```

Update `accepted` (closed as completed) or `declined` (closed as not planned). Mention any that upstream has fixed — that is usually a cue to run `/mission-control:preflight-check`.

## Guidelines

### The default outcome is joining an issue

New issues are the exception. A skill that opens one per mission per project produces a tracker nobody can read.

### Vanity is the failure mode

The gate's second criterion exists because subjective preference is the easiest thing to generate and the least useful thing to receive. An observed cost is the price of admission. A report with no cost is an opinion, and opinions do not converge.

### Terse is a kindness

The maintainer reads every one of these. Under 200 words, plain words, no preamble.

### One report, one difficulty

Two frictions are two reports even when found in the same debrief. A merged report cannot be individually confirmed, closed, or counted.

## Output

Deliverable: the service report artifact(s), persisted per `ARTIFACTS.md`.

Report per finding: the gate outcome, the search classification, what was sent (new issue / comment / reaction / nothing), and the upstream link.
