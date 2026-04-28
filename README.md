# LinkedIn Post Generator

Automate daily LinkedIn posts using Ollama for content generation and GitHub Actions for scheduling, publishing, and archiving.

## Overview

This project is designed to:

- Generate a post with Ollama from a rotating prompt list.
- Save the generated post to `post.txt`.
- Publish the post to LinkedIn using the UGC Posts API.
- Archive each generated post under `posts/`.
- Run automatically on a schedule using GitHub Actions.

## How It Works

1. A scheduled GitHub Actions workflow runs once per day.
2. The workflow runs `scripts/generate_post.sh` to select a prompt from `prompts/prompts.txt` and generate `post.txt` with Ollama.
3. The workflow runs `scripts/post_to_linkedin.sh` to publish the post via the LinkedIn UGC API.
4. The workflow copies the generated post into `posts/post-<timestamp>.txt` and uploads `post.txt` as a workflow artifact.

## Prerequisites

- A GitHub repository with Actions enabled.
- A self-hosted GitHub Actions runner with Ollama installed.
- `jq` and `curl` installed on the self-hosted runner.
- `bash` available on the runner.
- A LinkedIn Developer App.
- A LinkedIn OAuth access token with the required permission:
  - `w_member_social`
- Your LinkedIn member URN (example: `urn:li:person:YOUR_USER_ID`).

## Repository Secrets

Configure the following in GitHub repository secrets:

- `LINKEDIN_TOKEN`: LinkedIn OAuth access token.
- `LINKEDIN_AUTHOR_URN`: Your LinkedIn author URN.
- `OLLAMA_MODEL` (optional): Model name to use (example: `llama3`).

The generation script also supports these environment variables when run locally:

- `PROMPTS_FILE`: Path to the prompt list file. Defaults to `prompts/prompts.txt`.
- `OUTPUT_FILE`: Path to the generated post file. Defaults to `post.txt`.
- `POST_FILE`: Path to the file published by `scripts/post_to_linkedin.sh`. Defaults to `post.txt`.
- `MAX_RETRIES`: Number of LinkedIn publish attempts. Defaults to `3`.
- `RETRY_DELAY_SECONDS`: Delay between retry attempts. Defaults to `5`.

## Quick Start

1. Add repository secrets in GitHub:

- `LINKEDIN_TOKEN`
- `LINKEDIN_AUTHOR_URN`
- `OLLAMA_MODEL` (optional)

2. Ensure your self-hosted runner has `ollama`, `jq`, `curl`, and `bash` available.
3. Update prompts in [prompts/prompts.txt](prompts/prompts.txt) if you want to change the post topics.
4. Run the workflow manually once with `workflow_dispatch` or run the scripts locally as described below.
5. Verify the post appears on your LinkedIn profile and review the archived copy in `posts/`.

## Local Preview

To generate a post locally without publishing it, run:

```bash
bash scripts/generate_post.sh
```

To generate a post locally and archive it into `posts/`, run:

```bash
bash scripts/generate_local_post.sh
```

To use a specific model locally, set `OLLAMA_MODEL` first:

```bash
OLLAMA_MODEL=llama3 bash scripts/generate_post.sh
```

You can also archive to a different folder if you want:

```bash
ARCHIVE_DIR=posts OLLAMA_MODEL=llama3 bash scripts/generate_local_post.sh
```

The generated post is written to `post.txt`. If you want to publish the file manually afterward, use:

```bash
LINKEDIN_TOKEN=... LINKEDIN_AUTHOR_URN=... bash scripts/post_to_linkedin.sh
```

On Windows, run the commands from Git Bash or WSL so the Bash scripts and `ollama` call work the same way as in the workflow.

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

The workflow in [.github/workflows/linkedin-post.yml](.github/workflows/linkedin-post.yml) already matches the current script-based flow.
You can adapt values as needed.

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
        shell: powershell
        env:
          OLLAMA_MODEL: ${{ secrets.OLLAMA_MODEL }}
        run: |
          $env:PROMPTS_FILE = "prompts/prompts.txt"
          $env:OUTPUT_FILE = "post.txt"
          & "C:\Program Files\Git\bin\bash.exe" -e -o pipefail scripts/generate_post.sh

      - name: Publish to LinkedIn
        shell: powershell
        env:
          LINKEDIN_TOKEN: ${{ secrets.LINKEDIN_TOKEN }}
          LINKEDIN_AUTHOR_URN: ${{ secrets.LINKEDIN_AUTHOR_URN }}
        run: |
          $env:POST_FILE = "post.txt"
          & "C:\Program Files\Git\bin\bash.exe" -e -o pipefail scripts/post_to_linkedin.sh

      - name: Archive generated post
        shell: powershell
        run: |
          New-Item -ItemType Directory -Force -Path posts | Out-Null
          $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
          Copy-Item post.txt "posts/post-$timestamp.txt"

      - name: Upload post artifact
        uses: actions/upload-artifact@v4
        with:
          name: latest-linkedin-post
          path: post.txt
```

## Prompt Rotation (Recommended)

Store multiple prompts in [prompts/prompts.txt](prompts/prompts.txt) and randomly pick one each run. Empty lines and lines that start with `#` are ignored. The generator also prefixes each prompt with instructions to return only the final post, which helps avoid obvious AI-style prefaces.

## Reliability Enhancements

- Retry logic is built into `scripts/post_to_linkedin.sh`.
- Generated posts are archived in the `posts/` directory.
- The workflow uploads `post.txt` as a workflow artifact.

## Future Improvements

- Add media and image posting support.
- Support posting to LinkedIn organization pages.
- Add multi-language generation.
- Add analytics and post history reporting.
