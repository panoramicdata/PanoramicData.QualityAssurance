# AI-Assisted QA Scripts

## Overview

These PowerShell scripts in `scripts/` provide AI-assisted analysis and automation for QA tasks. They help categorize tickets, assess quality, and automate testing where possible.

## When to Use These Scripts

| User Question | Script | Action |
|---------------|--------|--------|
| "What could be improved about MS-12345?" | Assess-TicketQuality.ps1 | Run assessment, explain findings |
| "Is this ticket ready to test?" | Assess-TicketQuality.ps1 | Check score (80+ = ready) |
| "What type of testing does this need?" | Auto-Triage.ps1 | Categorize as CLI/Playwright/Manual |
| "Can I test this on any environment?" | Auto-Triage.ps1 | Check environment indicators |
| "Generate a test for this ticket" | Generate-SmokeTest.ps1 | Create Playwright test file |
| "Verify the CLI commands work" | Auto-VerifyCLI.ps1 | Extract and run CLI commands |
| "Help me test this ticket" | Auto-Triage.ps1 -GeneratePrompt | Generate guided test prompt |

---

## Script Reference

### 1. Assess-TicketQuality.ps1

**Purpose**: Score ticket specification quality (0-100) and identify improvements needed.

```powershell
# Assess single ticket
.\scripts\Assess-TicketQuality.ps1 -IssueKey MS-12345

# Batch assess all Ready for Test tickets
.\scripts\Assess-TicketQuality.ps1 -BatchMode

# Only show tickets below score threshold
.\scripts\Assess-TicketQuality.ps1 -BatchMode -MinScore 60

# Apply quality labels to JIRA
.\scripts\Assess-TicketQuality.ps1 -IssueKey MS-12345 -ApplyLabels
```

**Quality Factors Assessed**:
| Factor | Weight | What It Checks |
|--------|--------|----------------|
| Component | 15% | JIRA component set |
| Description | 20% | Word count, detail level |
| Testability | 20% | Pass/fail criteria, acceptance criteria |
| Steps to Reproduce | 15% | Numbered steps (for bugs) |
| Current vs Expected | 15% | Both behaviors documented |
| Environment/Version | 10% | Fix version, environment mentioned |
| Attachments | 5% | Screenshots, logs |

**Score Interpretation**:
- **80-100 EXCELLENT**: Well-specified, ready to test
- **60-79 GOOD**: Minor improvements possible
- **50-59 ADEQUATE**: Some clarification needed
- **30-49 NEEDS IMPROVEMENT**: Request clarification
- **<30 POOR**: Cannot test without significant rework

**Labels Applied** (with -ApplyLabels):
- `ai-spec-excellent`, `ai-spec-good`, `ai-spec-adequate`, `ai-needs-clarification`

---

### 2. Auto-Triage.ps1

**Purpose**: Categorize tickets by test type, difficulty, and environment requirements.

```powershell
# Triage single ticket
.\scripts\Auto-Triage.ps1 -IssueKey MS-12345

# Triage all Ready for Test tickets
.\scripts\Auto-Triage.ps1 -OutputFile "triage-results.json"

# Apply triage labels to JIRA
.\scripts\Auto-Triage.ps1 -ApplyLabels

# Generate AI testing prompt for a ticket
.\scripts\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-12345

# Save prompt to file
.\scripts\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-12345 -PromptOutputFile "prompts/MS-12345.md"
```

**Categories Assigned**:

| Category | Labels | Meaning |
|----------|--------|---------|
| Test Type | `ai-triage-cli`, `ai-triage-playwright`, `ai-triage-both`, `ai-triage-manual` | How to test |
| Difficulty | `ai-difficulty-easy`, `ai-difficulty-medium`, `ai-difficulty-hard` | Effort required |
| Environment | `ai-any-environment`, `ai-config-specific`, `ai-tenant-specific` | Where to test |
| Automation | `ai-auto-testable` | Can be fully automated |

**Environment Indicators**:
- 🌍 **Any Environment**: Can test on test2, alpha, beta, etc.
- ⚙️ **Config-Specific**: Needs specific connections, integrations, or settings
- 🏢 **Tenant-Specific**: Requires specific customer/tenant data

---

### 3. Auto-VerifyCLI.ps1

**Purpose**: Extract CLI commands from ticket and verify they work.

```powershell
# Verify CLI commands in a ticket
.\scripts\Auto-VerifyCLI.ps1 -IssueKey MS-12345

# Dry run - show commands without executing
.\scripts\Auto-VerifyCLI.ps1 -IssueKey MS-12345 -DryRun

# Post results to JIRA comment
.\scripts\Auto-VerifyCLI.ps1 -IssueKey MS-12345 -PostToJira
```

**Features**:
- Extracts `magicsuite` commands from ticket description
- Detects test type (exit code, output format, error handling)
- Runs commands and captures output
- Verifies expected behavior
- Posts formatted results to JIRA

---

### 4. Generate-SmokeTest.ps1

**Purpose**: Generate Playwright smoke tests from ticket descriptions.

```powershell
# Generate test file
.\scripts\Generate-SmokeTest.ps1 -IssueKey MS-12345

# Generate and run immediately
.\scripts\Generate-SmokeTest.ps1 -IssueKey MS-12345 -RunTest

# Specify environment
.\scripts\Generate-SmokeTest.ps1 -IssueKey MS-12345 -Environment test2
```

**Output**: Creates `playwright/Magic Suite/Generated/{issue-key}-smoke.spec.ts`

**Templates Available**:
- Button visibility/click tests
- Dark mode/theme toggle tests
- Error message verification
- Modal dialog tests
- Page load verification

---

### 5. Pre-Test-Check.ps1

**Purpose**: Pre-flight check using Elastic logs before manual testing.

```powershell
# Check ticket readiness
.\scripts\Pre-Test-Check.ps1 -IssueKey MS-12345

# Check against specific environment
.\scripts\Pre-Test-Check.ps1 -IssueKey MS-12345 -Environment beta

# Check more days of logs
.\scripts\Pre-Test-Check.ps1 -IssueKey MS-12345 -DaysToCheck 14
```

**Output**:
- Readiness score (0-100)
- Error trends for affected components
- Recommendations (quick test / full test / investigate first)

---

## Workflow Examples

### "What could be improved about MS-12345?"

```powershell
# Run assessment
.\scripts\Assess-TicketQuality.ps1 -IssueKey MS-12345
```

Then explain the findings:
- If score < 60, list the recommendations
- Suggest specific JIRA markup improvements
- Offer to update the ticket description

### "Help me test MS-12345"

```powershell
# Generate a guided prompt
.\scripts\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-12345 -PromptOutputFile "prompts/MS-12345.md"
```

The generated prompt includes:
- Full ticket context
- Environment guidance
- Suggested test approach
- Manual verification questions
- Test checklist

### "Triage the Ready for Test backlog"

```powershell
# Assess quality of all tickets
.\scripts\Assess-TicketQuality.ps1 -BatchMode -MinScore 50

# Categorize by test type
.\scripts\Auto-Triage.ps1 -ApplyLabels
```

Then recommend:
- Start with `ai-any-environment` + `ai-difficulty-easy` tickets
- Request clarification on `ai-needs-clarification` tickets
- Assign `ai-triage-cli` tickets to CLI experts

---

## Improving Ticket Quality

When asked to improve a ticket, use this pattern:

1. **Run assessment**: `.\scripts\Assess-TicketQuality.ps1 -IssueKey MS-XXXXX`
2. **Review findings**: Look at ✗ and ⚠ items
3. **Suggest improvements** based on ticket type:

**For Bugs - Add these sections**:
```
h3. Steps to Reproduce
1. Navigate to [page]
2. Click [element]
3. Observe [behavior]

h3. Current Behavior
[What happens now - the bug]

h3. Expected Behavior
[What should happen]

h3. Acceptance Criteria
* When [condition], then [result]
```

**For Stories/Features - Add these sections**:
```
h3. Expected Behavior
[Detailed description of desired outcome]

h3. Acceptance Criteria
* User can [action]
* System displays [result]
* [Feature] is [state]

h3. Environment
Available on [environments]
```

4. **Fix markup issues**: Replace `\n` with actual line breaks, use `h3.` headings
5. **Re-run assessment** to verify improvement

---

## Environment Requirements

All scripts use Windows Credential Manager for JIRA authentication.

On first run, you will be prompted to enter and store your credentials.
Credentials are stored under the target name `PanoramicData.JIRA`.

To manually manage credentials:
```powershell
# View stored credential
cmdkey /list:PanoramicData.JIRA

# Delete stored credential (to re-enter)
cmdkey /delete:PanoramicData.JIRA
```
