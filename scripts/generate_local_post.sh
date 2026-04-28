#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATE_SCRIPT="$SCRIPT_DIR/generate_post.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_FILE="${OUTPUT_FILE:-post.txt}"
ARCHIVE_DIR="${ARCHIVE_DIR:-$REPO_ROOT/posts}"

if [[ ! -f "$GENERATE_SCRIPT" ]]; then
  echo "Error: generate_post.sh not found at $GENERATE_SCRIPT"
  exit 1
fi

bash "$GENERATE_SCRIPT"

if [[ ! -s "$OUTPUT_FILE" ]]; then
  echo "Error: Generated post file is empty: $OUTPUT_FILE"
  exit 1
fi

mkdir -p "$ARCHIVE_DIR"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive_file="$ARCHIVE_DIR/post-$timestamp.txt"
cp "$OUTPUT_FILE" "$archive_file"

echo "Archived generated post to $archive_file"