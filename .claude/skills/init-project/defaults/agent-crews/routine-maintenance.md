# Routine Maintenance — Project Crew

Crew definitions for codebase health inspection. The Flight Director
coordinates an Inspector for automated checks and an Architect for severity assessment.

## Crew

### Inspector
- **Context**: {project}/
- **Model**: Sonnet
- **Role**: Performs read-only codebase inspection across all applicable categories.
  Runs test suites, linters, type checkers, audit commands, and manual code review.
  Returns structured findings without modifying any files.
- **Actions**: inspect-codebase

### Architect
- **Context**: {project}/
- **Model**: Sonnet
- **Role**: Reviews Inspector findings alongside debrief context (if available). Assigns
  final severity per finding, produces overall codebase assessment, and recommends
  maintenance scope if warranted.
- **Actions**: assess-findings

## Interaction Protocol

### Inspection
1. Flight Director loads mission context and debriefs (if available) and project stack info
2. Flight Director conducts category scoping interview with human
3. Flight Director spawns **Inspector** with applicable categories and known debt context
4. Inspector performs read-only checks and returns structured findings

### Assessment
1. Flight Director spawns **Architect** with Inspector findings + debrief context
2. Architect assigns severity per finding and overall assessment
3. Architect recommends maintenance scope if Action Required or Critical findings exist

### Human Review and Scoping
1. Flight Director presents findings to human, grouped by severity
2. Human confirms, overrides, or adjusts findings
3. If Maintenance Required: Flight Director recommends a shortlist (~5-7 items); human selects scope for maintenance mission
4. Deferred findings remain in the report for future cycles

### Synthesis
1. Flight Director generates maintenance report artifact
2. If confirmed: Flight Director creates maintenance mission scaffold

## Template Variables

The Flight Director substitutes these variables in prompts at runtime:

| Variable | Description |
|----------|-------------|
| `{project-slug}` | Project identifier from projects.md |
| `{applicable-categories}` | Numbered list of categories to inspect (1-7 always, 8-10 conditional) |
| `{project-stack}` | Language, framework, test runner, linter, formatter, type checker, audit tool |
| `{known-debt}` | Debt items from mission debrief and flight debriefs (if available, otherwise "None — ad-hoc inspection") |
| `{areas-of-concern}` | User-specified areas of concern from scoping interview |

## Prompts

### Inspector: Inspect Codebase

```
role: inspector
phase: routine-maintenance
project: {project-slug}
action: inspect-codebase

Perform a read-only codebase inspection across the following categories:
{applicable-categories}

Project stack: {project-stack}

Known debt from prior debriefs, if available (do not re-flag as new discoveries):
{known-debt}

User areas of concern:
{areas-of-concern}

IMPORTANT: You are strictly READ-ONLY. You may run test suites, linters, type
checkers, audit commands, and read any file. You must NEVER modify source files,
configuration, dependencies, or any other project file.

For each applicable category, perform the checks listed below and report findings.

**Category 1 — Security**:
- Review auth paths (focus on recently changed code if mission context is available)
- Check input sanitization on endpoints
- Verify CORS/CSP configuration
- Scan for hardcoded secrets (API keys, tokens, passwords)
- Review third-party data flow for exposure risks

**Category 2 — Test Systems**:
- Run the test suite and report results
- Check coverage delta (if tooling available)
- Find new code paths without test coverage
- Detect flaky tests (tests that pass/fail inconsistently)
- Check test performance (slow tests)
- Find hardcoded test data that should be fixtures

**Category 3 — Dependency Health**:
- Run the dependency audit command (npm audit, cargo audit, etc.)
- Check for outdated dependencies
- Find unused dependencies
- Verify lockfile is consistent
- Check license compliance
- Check for Dependabot/Renovate PRs and security alerts
- Assess auto-merge eligibility for patch updates

**Category 4 — Code Quality**:
- Run linter and formatter check (report violations, do NOT fix)
- Find dead code (unused exports, unreachable branches)
- Grep for TODOs/FIXMEs/HACKs (focus on recently introduced ones if mission context is available)
- Detect code duplication
- Check pattern consistency with existing codebase

**Category 5 — Type & API Safety**:
- Run the type checker and report errors
- Find `any` casts (TypeScript), `unsafe` blocks (Rust), or equivalent
- Check for unhandled errors or missing error types
- Detect API contract drift (mismatched types between client/server)
- Find deprecated API usage

**Category 6 — Documentation**:
- Check README accuracy against current state
- Verify new public interfaces have documentation
- Find stale comments referencing old behavior
- Check CHANGELOG for completeness
- Verify CLAUDE.md accuracy

**Category 7 — Git & Branch Hygiene**:
- List stale branches (merged but not deleted)
- Find large committed files (>1MB)
- Scan for secrets in recent git history
- Check commit message quality
- Check for GitHub/remote warnings (secret scanning, code scanning alerts)
- Find merge conflicts against main
- Check upstream divergence

**Category 8 — CI/CD Pipeline** (if applicable):
- Check CI status on main/default branch
- Detect build time regression
- Find skipped or disabled checks
- Check config drift between environments

**Category 9 — Infrastructure & Config** (if applicable):
- Check env var documentation (.env.example vs actual usage)
- Find pending database migrations
- Find temporary feature flags that should be removed

**Category 10 — Performance & Observability** (if applicable):
- Find new operations without logging/tracing
- Detect potential N+1 queries
- Check bundle size (if web project)
- Find resource cleanup issues (unclosed connections, missing cleanup)

**Output format**: Return findings as a structured list per category:

## Category {N}: {Name}

### Finding: {title}
- **Evidence**: {what you found, with file paths and line numbers}
- **Impact**: {what could go wrong}
- **Recommendation**: {what to do about it}

If a category has no issues, report:
## Category {N}: {Name}
No issues found.
```

### Architect: Assess Findings

```
role: architect
phase: routine-maintenance
project: {project-slug}
action: assess-findings

Review the Inspector's findings and assign severity ratings. You have access to:
- Inspector findings (provided below)
- Known debt context from debriefs and prior maintenance reports (if available)

For each finding, assign one of:
- **Pass** — No issue (Inspector flagged something that is actually fine)
- **Advisory** — Minor issue, acceptable to defer
- **Action Required** — Should be addressed before next major work cycle
- **Critical** — Blocks further work, immediate attention needed

Known debt from debriefs, if available (already acknowledged — note as "previously identified" if re-found):
{known-debt}

**Assessment criteria**:
- Does this finding represent a real risk, or is it noise?
- Is the severity proportional to the actual impact?
- Would this compound if left for another cycle?
- Is this a new discovery or previously acknowledged debt?

**Output format**:

## Overall Assessment
{Flight Ready | Maintenance Required}

## Findings

| # | Category | Finding | Severity | New/Known | Notes |
|---|----------|---------|----------|-----------|-------|
| 1 | {cat} | {title} | {severity} | {new/known} | {brief note} |

## Severity Summary
- Critical: {N}
- Action Required: {N}
- Advisory: {N}
- Pass: {N}

## Recommended Maintenance Scope
(Only if Maintenance Required)

Group related Action Required and Critical findings into suggested flight scopes:

### Flight: {suggested title}
- Finding #{N}: {title}
- Finding #{N}: {title}
- Rationale: {why these group together}
```
