#!/bin/bash
# SessionStart hook — surface Flight Control projects with pending methodology
# migrations so Mission Control can recommend /init-project proactively, rather
# than relying on the model to run a drift check on its own.
#
# Scans every project registered in projects.md with check-drift.sh and prints a
# concise heads-up (added to session context) for any with pending migrations.
# Silent no-op when projects.md is absent, so it is harmless for anyone using
# this repository without a local project registry.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECTS_MD="$REPO_ROOT/projects.md"
SRC="$REPO_ROOT/.claude/skills/init-project"
DRIFT="$SRC/check-drift.sh"

[[ -f "$PROJECTS_MD" && -x "$DRIFT" ]] || exit 0

report=""
slug=""
while IFS= read -r line; do
  case "$line" in
    "## "*)
      slug="${line#\#\# }"
      slug="${slug%% *}"
      ;;
    "| Path |"*)
      path="${line#*\`}"
      path="${path%%\`*}"
      [[ -n "$path" ]] || continue
      out="$(bash "$DRIFT" "$SRC" "$path/.flightops" 2>/dev/null || true)"
      ids="$(printf '%s\n' "$out" | sed -n 's/^migration-pending:\(.*\)$/\1/p' | paste -sd, -)"
      [[ -n "$ids" ]] && report+="  - ${slug} (${ids})"$'\n'
      ;;
  esac
done < "$PROJECTS_MD"

[[ -n "$report" ]] || exit 0

summary="Flight Control projects with pending methodology migrations:
${report}Recommend /preflight-check (all) or /init-project (one project) to apply. Recommend only — do not apply migrations yourself."

# Emit as SessionStart JSON: systemMessage makes it visible to the operator;
# additionalContext injects it into the model's context. Fall back to plain
# stdout if python3 is unavailable.
if command -v python3 >/dev/null 2>&1; then
  python3 - "$summary" <<'PY'
import json, sys
msg = sys.argv[1]
print(json.dumps({
    "systemMessage": msg,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": msg,
    },
}))
PY
else
  printf '%s\n' "$summary"
fi
