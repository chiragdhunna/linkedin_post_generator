#!/usr/bin/env bash
set -euo pipefail

PROMPTS_FILE="${PROMPTS_FILE:-prompts/prompts.txt}"
OUTPUT_FILE="${OUTPUT_FILE:-post.txt}"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "Error: ollama is not installed or not in PATH."
  exit 1
fi

if [[ ! -f "$PROMPTS_FILE" ]]; then
  echo "Warning: $PROMPTS_FILE not found. Using default prompt."
  PROMPT="Write a short professional LinkedIn post about fintech and technology. Keep it under 120 words."
else
  # Ignore empty lines and comments that start with '#'.
  mapfile -t PROMPTS < <(grep -Ev '^\s*(#|$)' "$PROMPTS_FILE")
  if [[ ${#PROMPTS[@]} -eq 0 ]]; then
    echo "Error: No valid prompts found in $PROMPTS_FILE."
    exit 1
  fi
  INDEX=$((RANDOM % ${#PROMPTS[@]}))
  PROMPT="${PROMPTS[$INDEX]}"
fi

echo "Using model: $OLLAMA_MODEL"
echo "Selected prompt: $PROMPT"

ollama run "$OLLAMA_MODEL" "$PROMPT" > "$OUTPUT_FILE"

if [[ ! -s "$OUTPUT_FILE" ]]; then
  echo "Error: Generated post file is empty."
  exit 1
fi

echo "Post generated successfully at $OUTPUT_FILE"
