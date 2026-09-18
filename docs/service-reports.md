# Service Reports

A **service report** carries one Flight Control methodology difficulty back to the plugin as a GitHub issue. It is the only artifact that leaves the project.

## Why Service Reports Exist

Debriefs already ask whether the methodology itself got in the way — flight debriefs in their skill-effectiveness analysis, mission debriefs in their methodology feedback section. Until now that feedback had nowhere to go. Operators of a widely distributed plugin cannot open a pull request against it as part of their day, and the friction they hit is exactly the friction its maintainers cannot see. It accumulated in debrief files, one project at a time, and stayed there.

## The Aviation Model

A squawk is a defect in *this* aircraft, cleared by *this* operator. A **service difficulty report** runs the other way: the operator tells the manufacturer that the type design has a problem, because every other operator of that type will hit it too. The manufacturer aggregates reports across the fleet, finds the pattern, and issues a change.

Two features of that model matter here. Operators report *difficulties*, not designs — what happened and what it cost, not what should be built instead. And reports are only useful in aggregate: one is an anecdote, forty with the same signature is a defect.

## Mission Level, Not Flight Level

Reports are raised after `/mission-control:mission-debrief`, never after a single flight.

A flight is too small a sample. Any one flight can go badly for reasons that have nothing to do with the methodology, and a skill that files an issue per flight per project produces a tracker nobody can read. A mission is several flights, which is the smallest sample that yields the thing maintainers actually need: **recurrence**. "Hit in 3 of 5 flights" is evidence. "Hit once" is an afternoon.

So flight debriefs record, mission debriefs count and decide, and `/mission-control:service-report` files. Each level does the part it has the information for.

## Qualification

A finding is reportable only if **all five** hold:

1. **Reproduces from the methodology alone** — an operator on a different stack, language, and domain would hit it
2. **Has an observed cost** — rework, a re-run, a wrong artifact, a missed gate, a stall
3. **Not already fixed upstream** — checked against the installed plugin version and closed issues
4. **Not project-owned surface** — `ARTIFACTS.md` and the crew files are customizable by design; friction there is a local edit
5. **Statable with zero project information**

Criteria 3 and 4 reject more than expected. A large share of "the methodology is broken" turns out to be methodology drift — the project is running an old plugin — or a project that has customized its own artifact conventions into a corner. Both have local remedies, and routing them upstream wastes everyone's time.

Criterion 2 is the anti-vanity gate. Subjective preference is the cheapest thing to generate and the least useful thing to receive; requiring an observed cost is what makes reports converge on real improvements rather than accumulate as taste.

Criterion 5 has no workaround. A finding that cannot be stated without project information is not filed, however real it is.

## Never Leaking the Project

Sanitization is structural, not a review step at the end.

The report is **written from scratch in methodology vocabulary**, never copied from the debrief and scrubbed — scrubbing is how leaks survive. Methodology terms (`leg`, `flight`, `acceptance criteria`, skill and artifact names) are the shared language of every operator and belong in the report. Project terms never appear. The test is that the report must be reconstructible from the methodology alone: if a reader needs to know what the project does, it is not ready.

Specificity and proprietary detail are not the same thing:

| | |
|---|---|
| Specific and safe | "A leg whose acceptance criteria named an interface the flight had not specified" |
| Proprietary | "Leg 03 of the billing-sync flight" |
| Neither | "The leg specs were unclear" |

Two checks then run on the draft, in order.

The first is **mechanical and authoritative**: a deny-list assembled from the environment — the git remote's owner and repository, the project directory name, the operator's git identity and home path, top-level directory names, the package manifest's project name — matched case-insensitively against the draft. Any hit is a hard fail and the draft is rewritten, not patched. Generic tokens are filtered out first, because a deny-list that fires on every draft gets ignored.

The second is a **Redaction Reviewer** agent, and it is worth being precise about what it can and cannot do. It is *not* context-free: a spawned agent inherits the project's `CLAUDE.md`, which usually names the project, its domain, and its stack. So it cannot answer "would an outsider recognise this project?" — it knows the referent, and will read a generalized phrase as obviously generic for exactly that reason. That is the informed-judge failure, and it is why the mechanical check runs first and carries the weight.

What the reviewer *can* do is catch what a deny-list cannot: sentences that would be unintelligible to a reader who knows only the methodology. Those sentences are carrying project context implicitly, without ever naming it. That is the question it is asked.

## Approval

Nothing is sent until the operator approves it: repository, target, and the full body verbatim, with a plain statement that this posts publicly under their GitHub account. Every outbound act is covered, not just the issue body — the **search query** is approved before it runs, because a query reaches GitHub and is attributable too, and a **reaction** gets the same question as a body despite having no text to show.

Projects that must not post to public repositories set the switch to disabled — and that switch fails closed. If the skill cannot determine that upstream reporting is affirmatively enabled, it stops and asks rather than assuming consent from an absent line.

There is no summary approval, no batch approval, and no unattended path. The test is whether a human can be asked and can answer before work continues — not which skill did the calling. A spawned agent or a scheduled run stops at `draft`; an operator who arrived through the mission debrief's handoff is present, and reporting proceeds normally.

## Joining Beats Filing

Opening a new issue is the last resort, not the default. Every report searches first — the project's own log of past reports, then upstream open and closed issues, then open PRs and recent commits on main — and classifies into one of four outcomes:

| Outcome | Action |
|---------|--------|
| **New** | Draft an issue |
| **Variant** — same root cause, different manifestation | React `+1`, then comment the occurrence on the existing issue |
| **Duplicate** — same root cause, nothing new to add | React `+1`. No comment |
| **Already fixed** | Not an issue. Run `/mission-control:preflight-check` |

A hundred operators filing separate issues for one defect buries it. The same hundred adding occurrences to one issue specifies it. The reaction goes on both joining branches, not just the silent one — otherwise the count measures "operators with nothing to add" rather than operators affected, which is the opposite of a ranking signal.

Choosing between them runs one test, out loud: **would a single change to the methodology fix both this occurrence and the existing issue?** Yes means variant or duplicate. No means new — and new gets filed, exception or not. Superficial similarity is not root-cause identity, and the failure mode of a join-biased design is a handful of magnet issues carrying eighty comments across four unrelated defects, unsplittable without reading all eighty. The operator who could have told them apart is long gone by then.

An occurrence comment is short and structured, and its load-bearing line is **Differs**: each occurrence either matches the existing report exactly, or names the one dimension it varies on. That tightens an issue's scope as reports accumulate instead of scattering the same defect across near-duplicates — and it doubles as the split signal. When the `Differs` lines on an issue stop clustering, and start naming three or four unrelated dimensions, the issue is carrying more than one defect and wants splitting. Reports folded into the new issue are marked `superseded` locally on the next refresh.

Issues and comments both end with a fixed trailer — plugin version, skill, phase, occurrences — in an identical format. That is deliberate and load-bearing: it is the only thing that makes a corpus of reports countable. Without it the maintainer has prose, and prose does not aggregate into "which skill, which phase, which version, how often."

## Style

Terse, plain, specific. Under 200 words. No preamble, no framing, no gratitude.

**Report the difficulty, not the redesign.** There is no proposed-solution section by default. Operators report what happened and what it cost; the maintainer designs the fix with the whole fleet's reports in view, which no single operator has. At most one line of suggested direction, and only if the operator asks for it.

No quality adjectives — "confusing", "clunky", "awkward" — without the observable that produced them. If two operators could not recognise the same thing from the text, it is not specific enough yet.

## The Local Record

Every report leaves an artifact in the project, including the ones that were withheld. It holds the finding, the gate outcome, what the prior-art search found, the redaction verdict, the operator's approval, and the submitted text verbatim — the audit trail of exactly what left the project. Unlike the issue body, the local artifact may reference local debrief paths.

Status runs `draft → submitted | merged | withheld`, then `accepted`, `declined`, or `superseded` once upstream responds. `/mission-control:service-report list` refreshes anything carrying an issue number; records without one are never dereferenced. A `draft` — a report written while `gh` was unavailable and handed to the operator to paste — is reported separately and asked about, because an unanswered draft is a report that quietly never left.

## See Also

- [Squawks](squawks.md) — the same idea pointed inward: small defects in this codebase
- [Missions](missions.md) — where methodology feedback is weighed
- [Workflow](workflow.md) — end-to-end flow
