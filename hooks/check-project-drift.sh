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
#
# Also checks whether a newer plugin version is published, since Claude Code does
# not refresh third-party marketplaces unless auto-update is on. The latest
# version is read from plugin.json on the repository's default branch at most
# once a day; the result is cached in the plugin's data directory. Skipped when
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC is set or curl is unavailable.

set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$PLUGIN_ROOT/skills/init-project"
DRIFT="$SRC/check-drift.sh"
MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
FLIGHTOPS="$PROJECT_DIR/.flightops"
CACHE_DIR="${CLAUDE_PLUGIN_DATA:-${XDG_CACHE_HOME:-$HOME/.cache}/mission-control}"
CACHE_FILE="$CACHE_DIR/latest-version"
CACHE_TTL=86400

[[ -f "$DRIFT" ]] || exit 0
[[ -d "$FLIGHTOPS" || -d "$PROJECT_DIR/.flight-ops" ]] || exit 0

# ---- Plugin update check ----

# First "key": "value" string in a JSON file or stdin
json_field() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "${2:--}" | head -n 1
}

# Echo -1, 0 or 1 comparing dot-separated identifiers, numerically where both are numbers
cmp_ids() {
  local IFS=. i x y
  local -a a b
  read -ra a <<<"$1"
  read -ra b <<<"$2"
  for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
    x="${a[i]:-}" y="${b[i]:-}"
    [[ "$x" == "$y" ]] && continue
    if [[ -z "$x" ]]; then echo -1
    elif [[ -z "$y" ]]; then echo 1
    elif [[ "$x" =~ ^[0-9]+$ && "$y" =~ ^[0-9]+$ ]]; then
      if ((10#$x < 10#$y)); then echo -1; else echo 1; fi
    elif [[ "$x" < "$y" ]]; then echo -1
    else echo 1
    fi
    return
  done
  echo 0
}

# Succeed when semver $1 is older than $2; a prerelease is older than its release
version_behind() {
  local a="${1%%+*}" b="${2%%+*}" ap="" bp="" c
  [[ "$a" == *-* ]] && ap="${a#*-}"
  [[ "$b" == *-* ]] && bp="${b#*-}"
  c="$(cmp_ids "${a%%-*}" "${b%%-*}")"
  [[ "$c" != 0 ]] && { [[ "$c" == -1 ]]; return; }
  [[ -n "$ap" && -z "$bp" ]] && return 0
  [[ -z "$ap" || -z "$bp" ]] && return 1
  [[ "$(cmp_ids "$ap" "$bp")" == -1 ]]
}

latest_version() {
  local now stamp cached repo url latest=""
  now="$(date +%s)"
  if [[ -f "$CACHE_FILE" ]]; then
    { read -r stamp; read -r cached; } <"$CACHE_FILE"
    if [[ "${stamp:-}" =~ ^[0-9]+$ ]] && ((now - stamp < CACHE_TTL)); then
      printf '%s' "${cached:-}"
      return
    fi
  fi
  [[ -z "${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-}" ]] || return
  command -v curl >/dev/null 2>&1 || return
  repo="$(json_field repository "$MANIFEST" | sed -n 's|^https://github\.com/\([^/]*/[^/]*\)$|\1|p')"
  repo="${repo%.git}"
  [[ -n "$repo" ]] || return
  url="https://raw.githubusercontent.com/$repo/HEAD/.claude-plugin/plugin.json"
  latest="$(curl -fsSL --max-time 4 "$url" 2>/dev/null | json_field version)"
  # Cache failures too, so an offline machine doesn't wait on every session start
  if mkdir -p "$CACHE_DIR" 2>/dev/null; then
    printf '%s\n%s\n' "$now" "$latest" >"$CACHE_FILE.$$" && mv -f "$CACHE_FILE.$$" "$CACHE_FILE"
  fi
  printf '%s' "$latest"
}

messages=()

installed="$(json_field version "$MANIFEST")"
latest="$(latest_version)"
if [[ -n "$installed" && -n "$latest" ]] && version_behind "$installed" "$latest"; then
  messages+=("Flight Control: mission-control $latest is available (installed: $installed). To update, open /plugin, update the marketplace mission-control was installed from, then update the plugin and restart; enabling auto-update for that marketplace keeps it current. Tell the operator — do not update the plugin yourself.")
fi

# ---- Project drift ----

out="$(bash "$DRIFT" "$SRC" "$FLIGHTOPS" 2>/dev/null || true)"

status="$(printf '%s\n' "$out" | sed -n 1p)"
crews="$(printf '%s\n' "$out" | sed -n 's/^crew-missing:\(.*\)$/\1/p' | paste -sd, -)"
crewdir="$(printf '%s\n' "$out" | sed -n 's/^agent-crews:\(missing\|empty\)$/\1/p')"
ids="$(printf '%s\n' "$out" | sed -n 's/^migration-pending:\(.*\)$/\1/p' | paste -sd, -)"

parts=()
[[ "$status" == "outdated" ]] && parts+=("methodology files outdated")
[[ -n "$crewdir" ]] && parts+=("crew directory $crewdir")
[[ -n "$crews" ]] && parts+=("crew files missing: $crews")
[[ -n "$ids" ]] && parts+=("migrations pending: $ids")

if [[ ${#parts[@]} -gt 0 ]]; then
  detail="$(printf '%s; ' "${parts[@]}")"
  detail="${detail%; }"
  messages+=("Flight Control: this project is behind the installed mission-control plugin ($detail). Recommend /mission-control:preflight-check for the full report or /mission-control:init-project to apply. Recommend only — do not apply migrations yourself.")
fi

[[ ${#messages[@]} -gt 0 ]] || exit 0

summary="${messages[*]}"

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
