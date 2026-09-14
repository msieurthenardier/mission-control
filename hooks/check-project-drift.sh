#!/bin/bash
# SessionStart hook — surface Flight Control methodology drift for the current
# project so the session can recommend remediation proactively, rather than
# relying on the model to run a drift check on its own.
#
# Runs check-drift.sh against the current project's .flightops directory and
# prints a one-line heads-up (added to session context) if the project is behind
# the installed plugin: outdated synced files, missing crew files, or pending
# migrations. Silent no-op when the project has no .flightops directory, so it is
# harmless in projects that don't use Flight Control.

set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$PLUGIN_ROOT/skills/init-project"
DRIFT="$SRC/check-drift.sh"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
FLIGHTOPS="$PROJECT_DIR/.flightops"

[[ -f "$DRIFT" ]] || exit 0
[[ -d "$FLIGHTOPS" || -d "$PROJECT_DIR/.flight-ops" ]] || exit 0

out="$(bash "$DRIFT" "$SRC" "$FLIGHTOPS" 2>/dev/null || true)"
[[ -n "$out" ]] || exit 0

status="$(printf '%s\n' "$out" | sed -n 1p)"
crews="$(printf '%s\n' "$out" | sed -n 's/^crew-missing:\(.*\)$/\1/p' | paste -sd, -)"
crewdir="$(printf '%s\n' "$out" | sed -n 's/^agent-crews:\(missing\|empty\)$/\1/p')"
ids="$(printf '%s\n' "$out" | sed -n 's/^migration-pending:\(.*\)$/\1/p' | paste -sd, -)"

parts=()
[[ "$status" == "outdated" ]] && parts+=("methodology files outdated")
[[ -n "$crewdir" ]] && parts+=("crew directory $crewdir")
[[ -n "$crews" ]] && parts+=("crew files missing: $crews")
[[ -n "$ids" ]] && parts+=("migrations pending: $ids")

[[ ${#parts[@]} -gt 0 ]] || exit 0

detail="$(printf '%s; ' "${parts[@]}")"
detail="${detail%; }"
summary="Flight Control: this project is behind the installed mission-control plugin ($detail). Recommend /mission-control:preflight-check for the full report or /mission-control:init-project to apply. Recommend only — do not apply migrations yourself."

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
