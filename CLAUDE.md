# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is the source of the **mission-control** Claude Code plugin, which ships the **Flight Control** methodology: an AI-first software development lifecycle using aviation metaphors. Sessions here are about developing the plugin itself — its skills, hooks, synced methodology files, and docs. Using Flight Control on a project happens in that project, with the plugin installed.

Flight Control organizes work into three hierarchical levels:

- **Missions** (human-optimized) — Define outcomes in human terms; one meaningful outcome, typically 1-3 flights
- **Flights** (balanced) — Technical specifications with pre/in/post-flight checklists; one coherent cluster of design decisions and risks
- **Legs** (AI-optimized) — Coherent feature slices with explicit acceptance criteria; boundaries sit at decision and risk points, not effort

Beside the hierarchy sits the **squawk** — a standalone artifact for a single bug fix or routine servicing update, with no parent mission, flight, leg, or debrief. Squawks are qualified by a strict gate (one item, no design decisions, bounded blast radius, verifiable); work that fails the gate is escalated to a flight or mission. See `docs/squawks.md`.

Pointing the other way is the **service report** — the feedback channel from projects back to this repository. A squawk records a defect in the consumer's codebase; a service report records a recurring defect in the methodology and files it here as a GitHub issue. It is **operator-invoked only, on no cadence**: nothing triggers it and no skill hands off to it. It sweeps the project's accumulated flight and mission debriefs for observations that turned out to be long-running trends, with a threshold of three independent occurrences across two missions — occurrences, not documents, since mission debriefs restate their flight debriefs. Debriefs record; the sweep decides. `routine-maintenance` may mention that a corpus has accumulated, recommend-only; nothing may invoke the sweep. See `docs/service-reports.md`. Its two absolute rules: nothing is sent without the operator approving the exact text, and a finding that cannot be stated without project information is never filed.

Alongside the planning hierarchy, Flight Control includes **behavior tests** — Zephyr-style multi-step acceptance tests run with two live AI agents (an Executor and an independent Validator) using the **Witnessed** pattern. See `skills/behavior-test/AUTHORING.md` for the authoring guide.

## Plugin Layout

```
.claude-plugin/plugin.json      # Manifest; skills and hooks are auto-discovered
.claude-plugin/marketplace.json # Single-plugin marketplace so /plugin install resolves this repo
skills/<name>/SKILL.md          # Eleven skills, invoked as /mission-control:<name>
skills/init-project/            # Also carries the synced methodology files (FLIGHT_OPERATIONS.md,
                                # README.md), templates/, defaults/agent-crews/, migrations.md,
                                # and check-drift.sh
hooks/hooks.json                # SessionStart hook wiring (uses ${CLAUDE_PLUGIN_ROOT})
hooks/check-project-drift.sh    # One-line drift notice for the current project
docs/                           # Methodology documentation
.github/ISSUE_TEMPLATE/         # Receiving end for service reports filed by plugin consumers
```

To run the plugin from this checkout while developing it: `claude --plugin-dir .` from another directory, or install it through the marketplace file. Skills in `skills/` are not auto-loaded by a plain session in this repo.

## How the Skills Run

- **Skills run from the project root.** The project is the current working directory. There is no registry of projects; every skill reads `.flightops/` relative to the cwd. Do not reintroduce absolute paths to projects or a central list of them.
- **`${SKILL_DIR}`** in a SKILL.md means the directory that SKILL.md was loaded from inside the installed plugin. Plugin-internal references (crew defaults, templates, the drift detector, a sibling skill's files) use it. Spawned agents never receive plugin paths; everything they need is copied into the project's `.flightops/` by `init-project`.
- **Cross-skill references** use the namespaced form `/mission-control:<skill>`, including in the synced methodology files and crew defaults that land in projects.
- **Planning skills produce documentation only.** `init-project`, `preflight-check`, `mission`, `flight`, `flight-debrief`, `mission-debrief`, and `routine-maintenance` create and update artifacts; they never modify source files. `agentic-workflow` and `squawk` orchestrate implementation by spawning separate agents; the orchestrator itself never edits source, however small the fix looks.
- **`service-report` is the only skill that sends anything outside the project.** It writes a local artifact and posts to this repository's issue tracker. Every change to it is a change to a disclosure path. The controls, in order of authority: a deny-list built from the project's git remote, directory name, operator identity, and paths, matched mechanically before anything else; then a Redaction Reviewer, which is *not* context-free (a spawned agent inherits the project's `CLAUDE.md`) and so is asked only what it can answer — which sentences would be unintelligible to a reader who knows just the methodology. Every outbound act is approved by the operator, including the search query and reactions, not only issue bodies. Do not add a batch, default-yes, or non-interactive submission path, and do not restate the reviewer as context-free.
- **Phase gates require confirmation.** Missions must be fully agreed before designing flights; flights before legs. Squawks sit outside these gates and use the qualification gate in `squawk` instead.

## Methodology Drift

Projects carry copies of the synced methodology files, crew defaults, and an `ARTIFACTS.md` that evolves through numbered migrations. When you change any of those in this repo, every initialized project drifts:

- Editing `skills/init-project/FLIGHT_OPERATIONS.md` or `README.md` makes projects report `outdated`. That is expected; `init-project` re-syncs them.
- Adding a crew default makes projects report `crew-missing`.
- A change that needs edits to project-owned files (`ARTIFACTS.md`, `CLAUDE.md`, crew files) needs a new migration: add detection to `skills/init-project/check-drift.sh` (the single source of detection) and an entry in `skills/init-project/migrations.md`. See "Adding Future Migrations" there.

The SessionStart hook surfaces drift in one line and recommends `/mission-control:preflight-check` or `/mission-control:init-project`. Hooks and skills recommend only; `init-project` owns applying migrations, with confirmation.

## Skill–Project Boundary

Project owners can customize `.flightops/ARTIFACTS.md` and `.flightops/agent-crews/*.md` freely. Skills must not couple to project-owned shape:

- **Do not read project-owned artifacts by section heading.** Frame extraction by intent — what the agent is looking for — and let it locate the content within whatever structure the project uses.
- **Do not write into project-owned artifacts at named anchors.** Describe the destination semantically. When appending a new section, suggest a heading without prescribing it as a contract.
- **Do not rely on crew prompt files to carry skill-required instructions.** The Flight Director issues per-spawn instructions directly from the SKILL.md. Crew files are project-modifiable scaffolding; SKILL.md is the protocol.
- **Defer to ARTIFACTS.md for the whole persistence procedure.** Storage location, format, and any project-defined actions at create and transition time. Protocol — state values, lifecycle, taxonomy, invariants — lives in the skills, never in ARTIFACTS.md.

## Lifecycle States

- **Missions**: `planning` → `active` → `completed` (or `aborted`)
- **Flights**: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`)
- **Legs**: `planning` → `ready` → `in-flight` → `landed` → `completed` (or `aborted`)
- **Squawks**: `open` → `in-progress` → `completed` (or `deferred`, `escalated`) — intentionally outside the unified lifecycle; a squawk has no planning phase
- **Service reports**: `draft` → `submitted` / `merged` / `withheld`, then `accepted` / `declined` / `superseded` — also outside the unified lifecycle

## Project Information Stays in Project Artifacts

Never store project-specific information in Claude Code memories. Issues, technical debt, design gaps, and lessons learned belong in the project's own Flight Control artifacts: flight logs, debriefs, mission known issues, and design decision sections. This rule ships to projects in `FLIGHT_OPERATIONS.md`. Memory here, if used at all, is reserved for methodology preferences and cross-cutting tooling notes.

## Never Leak Operator Identity

Never write the operator's machine username or absolute home paths (`/home/<user>/...`, `/Users/<user>/...`, `C:\Users\<user>\...`) into any generated content — artifacts, code, tests, commit messages, PR descriptions, log excerpts pasted into docs. Use repo-relative paths, `~/projects/<slug>/...`, or `<username>` placeholders instead. If you spot a leaked path in existing content, flag it and offer to scrub.

## Public Repository

This is a public repository. Keep all committed content anonymized:

- **No personal paths** — Use generic examples like `~/projects/my-app`, not actual home directories
- **No usernames** — Use placeholders like `username` in examples
- **No project-specific details** — Keep examples generic
- `.mcp.json` and `.claude/settings.local.json` are gitignored local configuration and are never committed
