#!/bin/bash
# check-drift.sh - Detect methodology drift for a Flight Control project
#
# Usage: check-drift.sh <source-dir> <target-dir>
#   <source-dir>  the init-project skill directory (holds synced files + defaults)
#   <target-dir>  the project's .flightops directory
#
# Line 1 - synced-file status (FLIGHT_OPERATIONS.md, README.md):
#   missing  - Neither .flightops/ nor .flight-ops/ exists in the project
#   outdated - Exists but one or more synced files differ from source
#   current  - All synced files match source
#
# Additional lines (zero or more, any order):
#   agent-crews:{missing|empty|present}  - Crew directory status
#   crew-missing:{filename}              - Default crew file absent (repeats per file)
#   migration-pending:{id}               - A registered migration applies (repeats);
#                                          see migrations.md for that id's rationale + actions
#
# This script is the single source of migration detection. migrations.md describes
# each migration's actions but no longer carries its own detection logic.
# ARTIFACTS.md and agent-crews/ are project-specific and never hash-synced; drift in
# them is surfaced only via migration-pending:* codes.

set -e

SOURCE_DIR="$1"
TARGET_DIR="$2"

if [[ -z "$SOURCE_DIR" || -z "$TARGET_DIR" ]]; then
  echo "Usage: check-drift.sh <source-dir> <target-dir>" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

# Resolve the actual target directory, falling back to legacy name
EFFECTIVE_TARGET="$TARGET_DIR"
LEGACY_FLIGHT_OPS=false

if [[ ! -d "$TARGET_DIR" ]]; then
  # Derive the legacy path: replace trailing .flightops with .flight-ops
  LEGACY_DIR="${TARGET_DIR%/.flightops}/.flight-ops"
  if [[ "$LEGACY_DIR" != "$TARGET_DIR" && -d "$LEGACY_DIR" ]]; then
    EFFECTIVE_TARGET="$LEGACY_DIR"
    LEGACY_FLIGHT_OPS=true
  else
    echo "missing"
    exit 0
  fi
fi

# ---- Synced-file status (line 1) ----
FILES_TO_CHECK=("FLIGHT_OPERATIONS.md" "README.md")
ALL_CURRENT=true

for FILE in "${FILES_TO_CHECK[@]}"; do
  SOURCE_FILE="$SOURCE_DIR/$FILE"
  TARGET_FILE="$EFFECTIVE_TARGET/$FILE"

  if [[ ! -f "$SOURCE_FILE" ]]; then
    continue
  fi

  if [[ ! -f "$TARGET_FILE" ]]; then
    ALL_CURRENT=false
    break
  fi

  SOURCE_HASH=$(sha256sum "$SOURCE_FILE" | cut -d' ' -f1)
  TARGET_HASH=$(sha256sum "$TARGET_FILE" | cut -d' ' -f1)

  if [[ "$SOURCE_HASH" != "$TARGET_HASH" ]]; then
    ALL_CURRENT=false
    break
  fi
done

if $ALL_CURRENT; then
  echo "current"
else
  echo "outdated"
fi

# ---- Crew directory status ----
CREW_DIR=""
LEGACY_PHASES=false

if [[ -d "$EFFECTIVE_TARGET/agent-crews" ]]; then
  CREW_DIR="$EFFECTIVE_TARGET/agent-crews"
elif [[ -d "$EFFECTIVE_TARGET/phases" ]]; then
  CREW_DIR="$EFFECTIVE_TARGET/phases"
  LEGACY_PHASES=true
fi

if [[ -z "$CREW_DIR" ]]; then
  echo "agent-crews:missing"
elif [[ -z "$(ls -A "$CREW_DIR" 2>/dev/null)" ]]; then
  echo "agent-crews:empty"
else
  echo "agent-crews:present"
  # Check for missing crew files (new skills added since init)
  DEFAULT_CREWS_DIR="$SOURCE_DIR/defaults/agent-crews"
  if [[ -d "$DEFAULT_CREWS_DIR" ]]; then
    for DEFAULT_FILE in "$DEFAULT_CREWS_DIR"/*.md; do
      BASENAME=$(basename "$DEFAULT_FILE")
      if [[ ! -f "$CREW_DIR/$BASENAME" ]]; then
        echo "crew-missing:$BASENAME"
      fi
    done
  fi
fi

# ---- Migration detection (single source of truth; actions live in migrations.md) ----
ARTIFACTS="$EFFECTIVE_TARGET/ARTIFACTS.md"

# 001 - legacy .flight-ops/ directory name
if $LEGACY_FLIGHT_OPS; then
  echo "migration-pending:001"
fi

# 002 - legacy phases/ crew directory name
if $LEGACY_PHASES; then
  echo "migration-pending:002"
fi

if [[ -f "$ARTIFACTS" ]]; then
  # 003 - legacy divergent lifecycle states.
  # Match legacy-only status tokens (queued/diverted) anywhere, plus the legacy
  # leg states (review/blocked) ONLY when adjacent to an enum pipe or a
  # state-tracking arrow — so prose that merely contains the words "review",
  # "blocked", or "completed" (e.g. a Jira-workflow section) doesn't false-fire.
  if grep -Eq '\b(queued|diverted)\b|(\||→)[[:space:]]*(review|blocked)\b|\b(review|blocked)[[:space:]]*(\||→)' "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:003"
  fi

  # 004 - behavior-test artifacts/crew not installed
  CREW_FILE_MISSING=true
  if [[ -n "$CREW_DIR" && -f "$CREW_DIR/behavior-tests-execution.md" ]]; then
    CREW_FILE_MISSING=false
  fi
  if $CREW_FILE_MISSING || ! grep -q "Behavior Test — Spec" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:004"
  fi

  # 005 - Git Conventions section not present
  if ! grep -q "## Git Conventions" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:005"
  fi

  # 006 - Squawk artifact section not present
  if ! grep -q "^### Squawk" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:006"
  fi

  # 009 - Service Report artifact section not present
  if ! grep -q "^### Service Report" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:009"
  fi

  # 011 - Sortie artifact section not present
  if ! grep -q "^### Sortie" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:011"
  fi

  # 012 - Leg format still carries the per-leg completion checklist, which 008
  # left behind; it names the retired [COMPLETE:leg] signal
  if grep -q "COMPLETE:leg" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:012"
  fi

  # 013 - Maintenance Report artifact section not present (projects initialized
  # before routine-maintenance shipped)
  if ! grep -q "^### Maintenance Report" "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:013"
  fi

  # 014 - artifact file names carrying the skill namespace (e.g.
  # mission-control:mission.md), left by the plugin reshape's find/replace
  if grep -Eq 'mission-control:[A-Za-z0-9_-]+\.md' "$ARTIFACTS" 2>/dev/null; then
    echo "migration-pending:014"
  fi
fi

# The project's CLAUDE.md may live at the project root or in .claude/ — Claude
# Code loads either as project instructions. Every candidate that carries a
# Flight Operations section is checked; a project with no section in any of them
# gets the current snippet from init-project step 7 without a migration.
PROJECT_ROOT="$(dirname "$EFFECTIVE_TARGET")"
CLAUDE_MD_CANDIDATES=("$PROJECT_ROOT/CLAUDE.md" "$PROJECT_ROOT/.claude/CLAUDE.md")
PENDING_007=false
PENDING_010=false

for CLAUDE_MD in "${CLAUDE_MD_CANDIDATES[@]}"; do
  if [[ ! -f "$CLAUDE_MD" ]] || ! grep -q "^## Flight Operations" "$CLAUDE_MD" 2>/dev/null; then
    continue
  fi
  # 007 - pre-plugin Flight Operations section: lacks the plugin-era Flight
  # Director instructions.
  if ! grep -q "mission-control:agentic-workflow" "$CLAUDE_MD" 2>/dev/null; then
    PENDING_007=true
  # 010 - plugin-era section that never binds the Flight Director role to the
  # interactive session.
  elif ! grep -q "never the Flight Director" "$CLAUDE_MD" 2>/dev/null; then
    PENDING_010=true
  fi
done

if $PENDING_007; then
  echo "migration-pending:007"
# 010 stays silent while 007 is pending; 007 installs the current snippet anyway.
elif $PENDING_010; then
  echo "migration-pending:010"
fi

# 008 - leg-execution crew file still speaks the per-leg review/commit protocol.
# Signals are methodology, not project customization (the crew file says so
# itself), so this is the one kind of crew-content drift that is a migration.
# Fires when the file names the retired [COMPLETE:leg] signal, or never tells the
# Developer to emit [LAND:leg]; silent once both hold.
if [[ -n "$CREW_DIR" && -f "$CREW_DIR/leg-execution.md" ]] \
   && { grep -q "COMPLETE:leg" "$CREW_DIR/leg-execution.md" 2>/dev/null \
        || ! grep -q "LAND:leg" "$CREW_DIR/leg-execution.md" 2>/dev/null; }; then
  echo "migration-pending:008"
fi
