#!/usr/bin/env bash
set -euo pipefail

POST_FILE="${POST_FILE:-post.txt}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-5}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCHIVE_DIR="${ARCHIVE_DIR:-$REPO_ROOT/posts}"

archive_post() {
  mkdir -p "$ARCHIVE_DIR"
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  archive_file="$ARCHIVE_DIR/post-$timestamp.txt"
  cp "$POST_FILE" "$archive_file"
  echo "Archived published post to $archive_file"
}

post_already_archived() {
  [[ ! -d "$ARCHIVE_DIR" ]] && return 1

  shopt -s nullglob
  for archived_post in "$ARCHIVE_DIR"/post-*.txt; do
    if cmp -s "$POST_FILE" "$archived_post"; then
      return 0
    fi
  done

  return 1
}

if [[ -z "${LINKEDIN_TOKEN:-}" ]]; then
  echo "Error: LINKEDIN_TOKEN is not set."
  exit 1
fi

if [[ -z "${LINKEDIN_AUTHOR_URN:-}" ]]; then
  echo "Error: LINKEDIN_AUTHOR_URN is not set."
  exit 1
fi

if [[ ! -f "$POST_FILE" ]]; then
  echo "Error: Post file not found: $POST_FILE"
  exit 1
fi

if post_already_archived; then
  echo "Post already exists in $ARCHIVE_DIR. Skipping publish to avoid reposting the same content."
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is not installed or not in PATH."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is not installed or not in PATH."
  exit 1
fi

CONTENT="$(cat "$POST_FILE")"

if [[ -z "$CONTENT" ]]; then
  echo "Error: Post content is empty."
  exit 1
fi

PAYLOAD_FILE="payload.json"

jq -n \
  --arg author "$LINKEDIN_AUTHOR_URN" \
  --arg text "$CONTENT" \
  '{
    author: $author,
    lifecycleState: "PUBLISHED",
    specificContent: {
      "com.linkedin.ugc.ShareContent": {
        shareCommentary: {
          text: $text
        },
        shareMediaCategory: "NONE"
      }
    },
    visibility: {
      "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
    }
  }' > "$PAYLOAD_FILE"

ATTEMPT=1
while [[ $ATTEMPT -le $MAX_RETRIES ]]; do
  echo "Publishing to LinkedIn (attempt $ATTEMPT/$MAX_RETRIES)..."

  HTTP_STATUS="$(curl -sS -o response.json -w "%{http_code}" \
    -X POST "https://api.linkedin.com/v2/ugcPosts" \
    -H "Authorization: Bearer $LINKEDIN_TOKEN" \
    -H "Content-Type: application/json" \
    --data @"$PAYLOAD_FILE")"

  if [[ "$HTTP_STATUS" =~ ^2 ]]; then
    echo "LinkedIn post published successfully."
    cat response.json
    archive_post
    exit 0
  fi

  echo "LinkedIn API request failed with status: $HTTP_STATUS"
  cat response.json || true

  if [[ $ATTEMPT -lt $MAX_RETRIES ]]; then
    echo "Retrying in $RETRY_DELAY_SECONDS seconds..."
    sleep "$RETRY_DELAY_SECONDS"
  fi

  ATTEMPT=$((ATTEMPT + 1))
done

echo "Error: Failed to publish LinkedIn post after $MAX_RETRIES attempts."
exit 1
