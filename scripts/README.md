# QA Automation Scripts

This folder contains automation scripts for accelerating QA testing.

## AI-Powered Acceleration Scripts

These scripts implement the 6 AI techniques described in [AI-QA-Acceleration-Plan.md](../docs/AI-QA-Acceleration-Plan.md).

### 1. Auto-Triage.ps1

**Purpose:** Categorize Ready for Test tickets by test type, difficulty, and environment specificity. Also generates AI prompts for testing.

```powershell
# Analyze and display categories
.\Auto-Triage.ps1 -OutputFile "triage-results.json"

# Apply AI labels to JIRA
.\Auto-Triage.ps1 -ApplyLabels -MaxResults 100

# Generate AI prompt for a specific ticket
.\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-22886

# Save prompt to file for later use
.\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-22886 -PromptOutputFile "prompts/ms-22886.md"
```

**Categories Applied:**
- `ai-triage-cli` / `ai-triage-playwright` / `ai-triage-both` / `ai-triage-manual`
- `ai-difficulty-easy` / `ai-difficulty-medium` / `ai-difficulty-hard`
- `ai-any-environment` / `ai-config-specific` / `ai-tenant-specific`
- `ai-auto-testable`

**Environment Specificity:**
| Indicator | Label | Meaning |
|-----------|-------|---------|
| 🌍 | `ai-any-environment` | Can test on any environment (test2, alpha, beta) |
| ⚙️ | `ai-config-specific` | Needs specific configuration/connections |
| 🏢 | `ai-tenant-specific` | Requires specific customer/tenant data |

**AI Prompt Generation:**
The `-GeneratePrompt` flag creates a prompt you can paste directly into GitHub Copilot, including:
- Full ticket details and description
- Environment guidance (which environment to use)
- Suggested test approach (CLI/Playwright/Manual)
- Manual verification steps (e.g., "Review the diagram and confirm layout")
- Test execution checklist

---

### 2. Auto-VerifyCLI.ps1

**Purpose:** Automatically verify CLI-related tickets by extracting and running commands.

```powershell
# Analyze ticket and run CLI commands
.\Auto-VerifyCLI.ps1 -IssueKey MS-22611 -Profile test2

# Post results to JIRA
.\Auto-VerifyCLI.ps1 -IssueKey MS-22611 -PostToJira

# Dry run - just show extracted commands
.\Auto-VerifyCLI.ps1 -IssueKey MS-22611 -DryRun
```

**Features:**
- Extracts CLI commands from ticket description
- Detects test type (exit code, output format, error handling)
- Runs commands and verifies behavior
- Posts formatted results to JIRA

---

### 3. Pre-Test-Check.ps1

**Purpose:** Pre-flight check using Elastic logs before starting manual testing.

```powershell
# Check ticket readiness
.\Pre-Test-Check.ps1 -IssueKey MS-22886

# Check against specific environment
.\Pre-Test-Check.ps1 -IssueKey MS-22886 -Environment beta -DaysToCheck 14
```

**Output:**
- Readiness score (0-100)
- Error trends for affected components
- Recommendations (quick test / full test / investigate)

---

### 4. Generate-SmokeTest.ps1

**Purpose:** Generate Playwright smoke tests from JIRA ticket descriptions.

```powershell
# Generate test file
.\Generate-SmokeTest.ps1 -IssueKey MS-22886

# Generate and run immediately
.\Generate-SmokeTest.ps1 -IssueKey MS-22886 -RunTest -Environment test2
```

**Templates:**
- Button visibility/click tests
- Dark mode/theme toggle tests
- Error message verification
- Modal dialog tests
- Generic page load tests

**Output:** `playwright/Magic Suite/Generated/{issue-key}-smoke.spec.ts`

---

### 5. Assess-TicketQuality.ps1

**Purpose:** Assess the quality and completeness of ticket specifications before testing.

```powershell
# Assess single ticket
.\Assess-TicketQuality.ps1 -IssueKey MS-22886

# Batch assess all Ready for Test tickets
.\Assess-TicketQuality.ps1 -BatchMode -MinScore 60

# Apply quality labels to JIRA
.\Assess-TicketQuality.ps1 -BatchMode -ApplyLabels

# Request clarification on low-scoring tickets
.\Assess-TicketQuality.ps1 -BatchMode -MinScore 50 -RequestClarification
```

**Quality Factors Assessed:**
| Factor | Weight | What We Check |
|--------|--------|---------------|
| Component | 15% | JIRA component set, app mentioned |
| Description | 20% | Word count, detail level |
| Testability | 20% | Pass/fail criteria, acceptance criteria |
| Steps to Reproduce | 15% | Numbered steps (for bugs) |
| Current vs Expected | 15% | Both behaviors documented (for bugs) |
| Environment/Version | 10% | Fix version, environment mentioned |
| Attachments | 5% | Screenshots, logs attached |

**Labels Applied:**
- `ai-spec-excellent` (80+)
- `ai-spec-good` (60-79)
- `ai-spec-adequate` (50-59)
- `ai-needs-clarification` (<50)

---

## Environment Requirements

### JIRA Credentials
All scripts use Windows Credential Manager for JIRA authentication.

On first run, you will be prompted to enter and store your credentials.
Credentials are stored under the target name `PanoramicData.JIRA`.

```powershell
# View stored credential
cmdkey /list:PanoramicData.JIRA

# Delete stored credential (to re-enter)
cmdkey /delete:PanoramicData.JIRA
```

### Elastic Credentials (if using Elastic scripts)
```powershell
$env:ELASTIC_USERNAME = "your.username"
$env:ELASTIC_PASSWORD = "your-password"
```

## Workflow Integration

### Daily Triage Workflow

```powershell
# 1. Run morning triage
.\Auto-Triage.ps1 -OutputFile "triage-$(Get-Date -Format 'yyyyMMdd').json" -ApplyLabels

# 2. Pick easy any-environment tickets first
# (Use JIRA filter: project=MS AND status="Ready for Test" AND labels="ai-difficulty-easy" AND labels="ai-any-environment")

# 3. For each ticket, generate an AI testing prompt
.\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-XXXXX

# 4. Copy the prompt into GitHub Copilot and follow the guided test
# (The prompt will tell Copilot to ask you for manual verification steps)

# 5. For CLI tickets - run automated verification
.\Auto-VerifyCLI.ps1 -IssueKey MS-XXXXX -PostToJira

# 6. For UI tickets - generate smoke test
.\Generate-SmokeTest.ps1 -IssueKey MS-XXXXX -RunTest
```

### AI-Assisted Testing Loop

```powershell
# For a specific ticket
$ticket = "MS-22886"

# 1. Generate AI prompt with full context
.\Auto-Triage.ps1 -GeneratePrompt -IssueKey $ticket -PromptOutputFile "prompts/$ticket.md"

# 2. Open VS Code and paste prompt into Copilot Chat
code "prompts/$ticket.md"

# 3. Copilot will guide you through:
#    - Setting up test environment
#    - Running automated checks
#    - Prompting for manual verification (e.g., "Does the chart look correct?")
#    - Documenting results
```

### Quick Verification Loop

```powershell
# For a specific ticket
$ticket = "MS-22886"

# 1. Pre-check
.\Pre-Test-Check.ps1 -IssueKey $ticket

# 2. Generate and run test
.\Generate-SmokeTest.ps1 -IssueKey $ticket -RunTest

# 3. Review screenshots in playwright/screenshots/
```

## Script Outputs

| Script | Primary Output | JIRA Integration |
|--------|----------------|------------------|
| Auto-Triage | JSON file + console | Labels (optional) |
| Auto-VerifyCLI | Console + JIRA comment | Comment (optional) |
| Pre-Test-Check | Console only | None |
| Generate-SmokeTest | .spec.ts file | None |

## Extending Scripts

All scripts follow the same pattern:
1. Get credentials from Windows Credential Manager via `Get-JiraCredentials.ps1`
2. Fetch ticket details via REST API
3. Analyze content using pattern matching
4. Perform action (categorize, run, generate)
5. Output results

To add new patterns, edit the `$xxxPatterns` hashtables at the top of each script.
