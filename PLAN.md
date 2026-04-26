# 📌 Project Plan: Automated LinkedIn Posting with Ollama + GitHub Actions

## 1. Project Setup

- **Repository Creation**
  - Create a GitHub repository (e.g., `linkedin-ollama-action`).
  - Add a README with purpose, usage, and setup instructions.
- **Secrets Configuration**
  - Store LinkedIn API token (`LINKEDIN_TOKEN`) in GitHub Secrets.
  - Store any other sensitive values (e.g., `OLLAMA_API_KEY` if required).

---

## 2. Core Components

### 2.1 Content Generation (Ollama)

- Install Ollama on a **self-hosted runner** (GitHub-hosted runners don’t support Ollama yet).
- Define prompts for daily post generation (e.g., motivational, tech insights, fintech tips).
- Save generated text to a file (`post.txt`).

### 2.2 LinkedIn API Integration

- Use LinkedIn’s **UGC Posts API** (`/ugcPosts`) for publishing.
- Requirements:
  - LinkedIn Developer App
  - OAuth 2.0 access token with `w_member_social` permission
  - Author URN (your LinkedIn user ID)
- Implement a script (`post_to_linkedin.sh` or Node.js/Python script) to send the API request.

### 2.3 GitHub Action Workflow

- Trigger: `schedule` event (cron job).
- Steps:
  - Checkout repo
  - Run Ollama to generate content
  - Call LinkedIn API with generated text

---

## 3. Workflow Example

```yaml
name: Daily LinkedIn Post

on:
  schedule:
    - cron: "0 9 * * *" # every day at 9 AM IST

jobs:
  linkedin-post:
    runs-on: self-hosted
    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Generate post with Ollama
        run: |
          ollama run llama3 "Write a short professional post about fintech and technology" > post.txt

      - name: Publish to LinkedIn
        run: |
          CONTENT=$(cat post.txt)
          curl -X POST "https://api.linkedin.com/v2/ugcPosts" \
            -H "Authorization: Bearer ${{ secrets.LINKEDIN_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d '{
              "author": "urn:li:person:YOUR_USER_ID",
              "lifecycleState": "PUBLISHED",
              "specificContent": {
                "com.linkedin.ugc.ShareContent": {
                  "shareCommentary": {
                    "text": "'"$CONTENT"'"
                  },
                  "shareMediaCategory": "NONE"
                }
              },
              "visibility": {
                "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
              }
            }'
```

## 4. Enhancements

### Content Variety

- Rotate prompts (e.g., motivational, fintech insights, coding tips).
- Use a prompt file (`prompts.txt`) and randomly select one daily.

### Error Handling

- Add retries if LinkedIn API fails.
- Log errors to GitHub Actions output for debugging.

### Analytics

- Store posted content in repo (`posts/` folder).
- Track post history for review and analysis.

### CI/CD

- Add linting/validation for generated content.
- Implement automated testing for scripts.

---

## 5. Future Extensions

- Add **images or media** to posts (LinkedIn supports media uploads).
- Integrate with **OpenAI or other LLMs** for richer content generation.
- Allow **organization page posting** instead of personal profile.
- Add **multi-language support** for broader reach.

---

## 6. Recommended Folder Structure

```text
linkedin-ollama-action/
├── .github/
│   └── workflows/
│       └── linkedin-post.yml   # GitHub Action workflow
├── scripts/
│   ├── generate_post.sh        # Ollama content generation script
│   └── post_to_linkedin.sh     # LinkedIn API integration script
├── prompts/
│   └── prompts.txt             # Rotating prompts for daily posts
├── posts/                      # Archive of generated and published posts
└── README.md                   # Project overview and usage guide
```
