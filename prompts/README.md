# AI Test Prompts

This folder contains AI-generated test prompts that QA engineers can paste directly into GitHub Copilot.

## How to Use

### 1. Generate a Prompt

```powershell
cd scripts
.\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-22886 -PromptOutputFile "../prompts/MS-22886.md"
```

### 2. Open in VS Code

```powershell
code ../prompts/MS-22886.md
```

### 3. Paste into Copilot Chat

Copy the entire contents and paste into GitHub Copilot Chat (Ctrl+Shift+I or the Copilot icon).

### 4. Follow the Guided Test

Copilot will:
- Suggest the appropriate test approach (CLI/Playwright/Manual)
- Run automated checks where possible
- **Prompt you for manual verification** when human judgment is needed
- Help document results for JIRA

## Prompt Structure

Each generated prompt includes:

| Section | Purpose |
|---------|---------|
| **Ticket Info** | Issue key, summary, type, priority |
| **Environment Guidance** | 🌍 Any / ⚙️ Config-specific / 🏢 Tenant-specific |
| **Suggested Approach** | CLI, Playwright, Manual, or combination |
| **Test Steps** | Extracted or generated test steps |
| **Manual Verification** | Questions for the QA engineer to answer |
| **Checklist** | Standard verification checklist |

## Example Manual Verification Prompts

When the AI encounters something that requires human judgment, it will ask:

- *"Please navigate to the chart and confirm: Does the layout look correct?"*
- *"After the report runs, please verify: Are the column headers aligned?"*
- *"Look at the exported PDF and confirm: Is the formatting preserved?"*
- *"Visually check the dashboard: Are all widgets loading without errors?"*

## File Naming

Prompts are saved as: `{IssueKey}.md` (e.g., `MS-22886.md`)

## Cleanup

Feel free to delete prompts after testing is complete - they can be regenerated anytime.
