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
fi
