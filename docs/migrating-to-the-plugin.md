# Migrating to the Plugin

This guide is for anyone who used Flight Control before it shipped as a Claude Code plugin — when `mission-control` was a repository you cloned, opened in Claude Code, and drove through a local `projects.md` registry. It covers moving your machine and each of your projects onto the `mission-control` plugin.

Nothing here touches your artifacts. Missions, flights, legs, squawks, flight logs, and debriefs stay exactly where the project's `.flightops/ARTIFACTS.md` put them, and their lifecycle states are unchanged.

If you never had a `projects.md` and have only ever run `/mission-control:<skill>` commands, you are already on the plugin — follow the [Getting Started](../README.md#getting-started) section of the README instead.

## What Changed

| Before (checkout) | After (plugin) |
|-------------------|----------------|
| Clone `mission-control` and open Claude Code **in the checkout** | Install the plugin once and open Claude Code **in the project** |
| `projects.md` registry maps a slug to a path and remote | No registry — the project is the current working directory |
| Skills invoked as `/init-project`, `/mission`, `/flight`, … | Skills invoked as `/mission-control:init-project`, `/mission-control:mission`, `/mission-control:flight`, … |
| Skills lived in the checkout's `.claude/skills/` | Skills ship inside the plugin |
| `/init-mission-control` created the registry | Removed — there is nothing to set up |
| `/daily-briefing` reported across every registered project | Removed — the plugin has no view outside the current project (see [Cross-project status](#cross-project-status)) |
| `/preflight-check` scanned every registered project | `/mission-control:preflight-check` diagnoses the current project only |
| SessionStart hook in the checkout's `.claude/settings.json` scanned the registry | Hook ships with the plugin and checks whichever project you open |
| Flight Director instructions lived in the checkout's `CLAUDE.md` | They live in each project's `CLAUDE.md`, in the Flight Operations section (migration 007) |
| Spawned agents were pointed at `{target-project}/` | Spawned agents inherit the project root as their working directory |

The methodology itself — missions, flights, legs, squawks, crews, behavior tests, debriefs — is unchanged. Only where it runs from and how you invoke it moved.

## Before You Start

- **Finish the current leg.** If `/agentic-workflow` is mid-run in an old checkout session, let it reach a leg boundary (or the end-of-flight review and commit) before switching. Orchestration state lives in that session, not on disk; artifacts are safe either way.
- **List your projects.** Your old `projects.md` is the list of projects to bring current in [Step 3](#step-3--bring-each-project-current). Keep it open until you have visited each one.

## Step 1 — Install the Plugin

From any Claude Code session:

```
/plugin marketplace add msieurthenardier/mission-control
/plugin install mission-control@flight-control
```

Or from a shell:

```bash
claude plugin marketplace add msieurthenardier/mission-control
claude plugin install mission-control@flight-control
```

Start a new Claude Code session so the skills and the SessionStart hook load. To confirm the install, type `/mission-control:` at the prompt — the ten skills should autocomplete — or run `claude plugin list` from a shell and check that `mission-control@flight-control` is listed and enabled.

## Step 2 — Retire the Checkout

Once the plugin is installed, the old checkout has nothing left to do:

1. **Delete `projects.md`.** Nothing reads it anymore. It was gitignored and never committed, and nothing needs to be migrated out of it — a project's path and remote are implied by the project you open.
2. **Delete the clone, or keep it for plugin development.** If you keep it, pull `main`. The old `.claude/settings.json` hook wiring and `.claude/skills/` directory are gone from `main`, so opening a session in the checkout no longer loads skills or scans projects. To run the plugin from the checkout while developing it, start Claude Code from a project with `claude --plugin-dir ~/projects/mission-control`, and disable the marketplace-installed copy first so the two do not both register the same skills.
3. **Remove anything else that pointed at the checkout** — shell aliases that `cd` there before planning, and any Claude Code memories that describe the registry or list your projects. Project information belongs in each project's own artifacts.

Do not try to run the old unnamespaced skills. If a session offers `/mission` or `/init-project` without the `mission-control:` prefix, it is running from an old checkout.

## Step 3 — Bring Each Project Current

Repeat for every project from your old `projects.md`, plus any other project that has a `.flightops/` (or older `.flight-ops/`) directory.

1. **Open Claude Code in the project's root.** The SessionStart hook prints a one-line notice, typically:

   > Flight Control: this project is behind the installed mission-control plugin (methodology files outdated; migrations pending: 007). Recommend /mission-control:preflight-check for the full report or /mission-control:init-project to apply.

   Projects that were behind before the plugin change may list earlier migrations too. That is fine; they are applied in order.

2. **Optionally run `/mission-control:preflight-check`** for the full diagnosis: which synced files differ, which crew files are missing, and which migrations are pending, with what each one would do.

3. **Run `/mission-control:init-project`** and confirm when prompted. It will:
   - **Apply migration 007** (after any earlier pending migrations). This replaces the Flight Operations section of the project's `CLAUDE.md` with the plugin-era snippet: namespaced skill names, the Flight Director role, the rule that spawned agents have no Skill tool, and the rule that drift notices are recommend-only. Anything you had added to that section beyond the old default is carried below the refreshed snippet — check that it landed where you want it.
   - **Re-sync the methodology files** `.flightops/FLIGHT_OPERATIONS.md` and `.flightops/README.md` to the plugin's copies.
   - **Offer to refresh crew files** in `.flightops/agent-crews/` against the new defaults. Pre-plugin crews describe the project slug as coming from `projects.md` and give spawned agents a `{target-project}/` working directory. Both are now informational — the slug is the repository directory name and agents inherit the project root — so refreshing is optional. Customized crew files are never rewritten without confirmation; review the diff before accepting.
   - **Add any crew defaults** the project is missing.

   It does not touch `ARTIFACTS.md`, and it does not touch any artifact.

4. **Review and commit** the changes to `CLAUDE.md` and `.flightops/`.

5. **Start a fresh session** in the project. The hook should now be silent.

## Step 4 — Update Your Habits

Every skill keeps its name and gains the `mission-control:` prefix. Two skills that only made sense with a registry are gone.

| Old command | New command |
|-------------|-------------|
| `/init-project` | `/mission-control:init-project` |
| `/preflight-check` | `/mission-control:preflight-check` |
| `/mission` | `/mission-control:mission` |
| `/flight` | `/mission-control:flight` |
| `/agentic-workflow` | `/mission-control:agentic-workflow` |
| `/squawk` | `/mission-control:squawk` |
| `/behavior-test <slug>` | `/mission-control:behavior-test <slug>` |
| `/flight-debrief` | `/mission-control:flight-debrief` |
| `/mission-debrief` | `/mission-control:mission-debrief` |
| `/routine-maintenance` | `/mission-control:routine-maintenance` |
| `/init-mission-control` | *(removed — no registry to set up)* |
| `/daily-briefing` | *(removed — see below)* |

**Where you work.** The Flight Director session is now a session in the project itself, started from its root. There is no separate Mission Control session and no need to pick a project — the project you opened is the target. Spawned agents run in the same root with fresh context.

**No project selection.** Skills no longer ask which project to target. They read `.flightops/` relative to the current directory.

## Cross-Project Status

The old `/daily-briefing` walked the registry and reported on every project at once. The plugin deliberately has no view outside the current project, and nothing replaces the cross-project report. What you have instead:

- The **SessionStart notice** tells you a project is behind the moment you open it.
- `/mission-control:preflight-check` gives the full drift report for the project you are in.
- `/mission-control:routine-maintenance` covers codebase health between missions, one project at a time.

If you want a sweep across many projects, keep your own list and open each one; the hook does the rest.

## Verify

You are done when all of the following hold:

- `claude plugin list` shows `mission-control@flight-control` installed and enabled.
- In each project, a new session prints no Flight Control drift notice, and `/mission-control:preflight-check` reports the project as current with no pending migrations.
- Each project's `CLAUDE.md` Flight Operations section refers to `/mission-control:agentic-workflow` (that line is what migration 007 checks for).
- The old checkout, if kept, has no `projects.md` and is on `main`.

## Troubleshooting

**Skills do not autocomplete.** The plugin is installed but not enabled, or the session predates the install. Run `claude plugin enable mission-control@flight-control` and start a new session.

**The hook keeps reporting migration 007.** The Flight Operations section in the project's `CLAUDE.md` still lacks the plugin-era instructions — usually because the migration was declined. Run `/mission-control:init-project` again and accept it. If you maintain that section by hand, make sure it references `/mission-control:agentic-workflow`; the drift detector keys on that string.

**A session asks for `projects.md` or suggests `/init-mission-control`.** Either the session is running from an old checkout (retire it, Step 2), or the project's `CLAUDE.md` still carries the pre-plugin Flight Operations section (apply migration 007, Step 3).

**A spawned agent tries to load a skill.** Its instructions come from a pre-plugin crew file or the pre-plugin `CLAUDE.md` section. Refresh the crew file against the defaults and confirm migration 007 was applied; the refreshed snippet tells agents they have no Skill tool and that everything they need is in `.flightops/`.

**Two copies of every skill appear.** The marketplace install and a `--plugin-dir` checkout are both loaded. Disable one: `claude plugin disable mission-control@flight-control` while developing from the checkout, and re-enable it afterwards.
