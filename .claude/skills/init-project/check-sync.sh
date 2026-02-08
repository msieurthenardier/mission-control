#!/bin/bash
# check-sync.sh - Compare .flight-ops directory between source and target
#
# Usage: check-sync.sh <source-dir> <target-dir>
#
# Outputs:
#   missing  - Target directory doesn't exist
#   outdated - Target exists but one or more files differ from source
#   current  - All files match source
#
# Note: Only checks synced files (README.md, FLIGHT_OPERATIONS.md).
#       ARTIFACTS.md and phases/ are project-specific and not synced.

set -e

SOURCE_DIR="$1"
TARGET_DIR="$2"

if [[ -z "$SOURCE_DIR" || -z "$TARGET_DIR" ]]; then
  echo "Usage: check-sync.sh <source-dir> <target-dir>" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

# Check if target directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "missing"
  exit 0
fi

# Compare each file in source directory
FILES_TO_CHECK=("FLIGHT_OPERATIONS.md" "README.md")
ALL_CURRENT=true

for FILE in "${FILES_TO_CHECK[@]}"; do
  SOURCE_FILE="$SOURCE_DIR/$FILE"
  TARGET_FILE="$TARGET_DIR/$FILE"

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

# Report on phases directory existence (not content — content is project-specific)
if [[ ! -d "$TARGET_DIR/phases" ]]; then
  echo "phases:missing"
elif [[ -z "$(ls -A "$TARGET_DIR/phases/" 2>/dev/null)" ]]; then
  echo "phases:empty"
else
  echo "phases:present"
fi
