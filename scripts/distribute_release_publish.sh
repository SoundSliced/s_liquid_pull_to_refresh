#!/usr/bin/env bash
# Distribute the local release_publish.sh script to multiple project folders.
# For each immediate child directory of a user-provided base path, if that child
# contains a 'scripts' directory, copy (overwrite) release_publish.sh into it.
# Skips directories without a 'scripts' subfolder.
#
# Usage: Just run this script and follow the prompt.
# Optional flags:
#   --dry-run    Show what would be done without copying
#   --help       Show help
#
# The source file is resolved relative to this script's own directory to avoid
# accidental mismatches when invoked from elsewhere.

set -euo pipefail
IFS=$'\n\t'

show_help() {
  cat <<'EOF'
Distribute release_publish.sh to multiple project folders.

Prompts for a BASE PATH. For each immediate child directory under BASE PATH:
  - If <child>/scripts exists, copies this project's release_publish.sh there (overwriting).
  - Otherwise, it prints a skip message.

Flags:
  --dry-run    Print planned actions only; nothing is copied.
  --help       Show this help and exit.

Examples:
  ./distribute_release_publish.sh
  ./distribute_release_publish.sh --dry-run
EOF
}

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) show_help; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; show_help; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/release_publish.sh"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "ERROR: Source release_publish.sh not found at $SOURCE_FILE" >&2
  exit 1
fi

echo "Enter the base path containing target project folders (absolute or relative)." >&2
read -r -p "Base path: " BASE_PATH
BASE_PATH=${BASE_PATH//\"/}

if [[ -z "$BASE_PATH" ]]; then
  echo "ERROR: No path provided." >&2
  exit 1
fi

# Resolve to absolute path
if [[ -d "$BASE_PATH" ]]; then
  BASE_PATH="$(cd "$BASE_PATH" && pwd)"
else
  echo "ERROR: Path does not exist or is not a directory: $BASE_PATH" >&2
  exit 1
fi

echo "Using base path: $BASE_PATH" >&2

total=0
copied=0
skipped=0

# Iterate immediate child directories
shopt -s nullglob
for child in "$BASE_PATH"/*; do
  [[ -d "$child" ]] || continue
  ((total++))
  scripts_dir="$child/scripts"
  project_name="$(basename "$child")"
  if [[ -d "$scripts_dir" ]]; then
    target="$scripts_dir/release_publish.sh"
    if $DRY_RUN; then
      echo "[DRY-RUN] Would copy $SOURCE_FILE -> $target" >&2
      ((copied++))
    else
      # Copy & preserve executable bit
      cp -f "$SOURCE_FILE" "$target"
      chmod +x "$target" || true
      echo "Copied to $project_name/scripts/" >&2
      ((copied++))
    fi
  else
    echo "Skipping $project_name (no scripts/ directory)" >&2
    ((skipped++))
  fi
done
shopt -u nullglob

echo "" >&2
echo "Summary:" >&2
echo "  Base path: $BASE_PATH" >&2
echo "  Total child directories inspected: $total" >&2
echo "  Release script copies (or would copy): $copied" >&2
echo "  Skipped (no scripts/): $skipped" >&2

if $DRY_RUN; then
  echo "Dry-run complete. Re-run without --dry-run to apply changes." >&2
fi

exit 0
