# LinkedIn Post Generator

Automate daily LinkedIn posts using Ollama for content generation and GitHub Actions for scheduling and publishing.

## Overview

This project is designed to:

- Generate professional post content using Ollama.
- Publish generated content to LinkedIn using the UGC Posts API.
- Run automatically on a schedule using GitHub Actions.

## How It Works

1. A scheduled GitHub Actions workflow runs once per day.
2. Ollama generates post content and saves it to a file.
3. The workflow sends the content to LinkedIn via API.

## Prerequisites

- A GitHub repository with Actions enabled.
- A self-hosted GitHub Actions runner with Ollama installed.
- `jq` installed on the self-hosted runner (used to build JSON safely).
- A LinkedIn Developer App.
- A LinkedIn OAuth access token with the required permission:
  - `w_member_social`
- Your LinkedIn member URN (example: `urn:li:person:YOUR_USER_ID`).

## Repository Secrets

Configure the following in GitHub repository secrets:

- `LINKEDIN_TOKEN`: LinkedIn OAuth access token.
- `LINKEDIN_AUTHOR_URN`: Your LinkedIn author URN.
- `OLLAMA_MODEL` (optional): Model name to use (example: `llama3`).

## Quick Start

1. Add repository secrets in GitHub:

- `LINKEDIN_TOKEN`
- `LINKEDIN_AUTHOR_URN`
- `OLLAMA_MODEL` (optional)

2. Ensure your self-hosted runner has `ollama`, `jq`, `curl`, and `bash` available.
3. Update prompts in `prompts/prompts.txt`.
4. Run the workflow manually once with `workflow_dispatch`.
5. Verify the post appears on your LinkedIn profile and review the workflow artifact.

## Suggested Project Structure

```text
linkedin_post_generator/
├── .github/
│   └── workflows/
│       └── linkedin-post.yml
├── scripts/
│   ├── generate_post.sh
│   └── post_to_linkedin.sh
├── prompts/
│   └── prompts.txt
├── posts/
├── PLAN.md
└── README.md
```

## Example Workflow

Place this in `.github/workflows/linkedin-post.yml` and adapt values as needed:

```yaml
name: Daily LinkedIn Post

on:
  schedule:
    - cron: "30 3 * * *" # 09:00 IST
  workflow_dispatch:

jobs:
  linkedin-post:
    runs-on: self-hosted
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Generate post with Ollama
        env:
          OLLAMA_MODEL: ${{ secrets.OLLAMA_MODEL }}
        run: |
          MODEL="${OLLAMA_MODEL:-llama3}"
          ollama run "$MODEL" "Write a short professional post about fintech and technology" > post.txt

      - name: Publish to LinkedIn
        env:
          LINKEDIN_TOKEN: ${{ secrets.LINKEDIN_TOKEN }}
          LINKEDIN_AUTHOR_URN: ${{ secrets.LINKEDIN_AUTHOR_URN }}
        run: |
          CONTENT=$(cat post.txt)
          jq -n \
            --arg author "$LINKEDIN_AUTHOR_URN" \
            --arg text "$CONTENT" \
            '{
              author: $author,
              lifecycleState: "PUBLISHED",
              specificContent: {
                "com.linkedin.ugc.ShareContent": {
                  shareCommentary: { text: $text },
                  shareMediaCategory: "NONE"
                }
              },
              visibility: {
                "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
              }
            }' > payload.json

          curl -X POST "https://api.linkedin.com/v2/ugcPosts" \
            -H "Authorization: Bearer $LINKEDIN_TOKEN" \
            -H "Content-Type: application/json" \
            --data @payload.json
```

## Prompt Rotation (Recommended)

Store multiple prompts in `prompts/prompts.txt` and randomly pick one each run. This keeps content varied (for example: motivational, fintech insights, coding tips).

## Reliability Enhancements

- Add retry logic for LinkedIn API requests.
- Archive published text in the `posts/` directory.
- Add content validation/linting before posting.

## Future Improvements

- Add media and image posting support.
- Support posting to LinkedIn organization pages.
- Add multi-language generation.
- Add analytics and post history reporting.
