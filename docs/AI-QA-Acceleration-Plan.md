# AI-Powered QA Acceleration Plan

**Date:** 2026-01-26  
**Context:** 380+ tickets in Ready for Test backlog  
**Goal:** Pragmatic, immediately deployable techniques to reduce QA backlog

---

## 🎯 The 6 Techniques

### 1. **Auto-Categorization & Triage Bot** (Deploy Today)
**What:** AI-powered script that analyzes all Ready for Test tickets and categorizes them by testability type, complexity, environment specificity, and recommended approach.

**Already Built:** See [ready-for-test-analysis.md](../ready-for-test-analysis.md) - 50 tickets already categorized.

**Categories Applied:**

| Category | Labels | Description |
|----------|--------|-------------|
| Test Type | `ai-triage-cli`, `ai-triage-playwright`, `ai-triage-both`, `ai-triage-manual` | How to test |
| Difficulty | `ai-difficulty-easy`, `ai-difficulty-medium`, `ai-difficulty-hard` | Effort level |
| Environment | `ai-any-environment`, `ai-config-specific`, `ai-tenant-specific` | Where to test |
| Automation | `ai-auto-testable` | Can be auto-verified |

**Environment Specificity Detection:**
- 🌍 **Any Environment** - Can test on test2, alpha, beta, etc. (buttons, colors, themes, general UI)
- ⚙️ **Config-Specific** - Needs particular settings/connections configured
- 🏢 **Tenant-Specific** - Requires specific customer data, Meraki/LogicMonitor/ConnectWise integrations, etc.

**Implementation:**
```powershell
# Batch triage with labels
.\scripts\Auto-Triage.ps1 -ApplyLabels -MaxResults 100

# Generate AI prompt for a specific ticket
.\scripts\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-22886

# Save prompt to file
.\scripts\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-22886 -PromptOutputFile "prompts/ms-22886.md"
```

**AI Prompt Generation:**
The `-GeneratePrompt` flag creates a ready-to-paste prompt for GitHub Copilot that includes:
- Ticket details and description
- Environment guidance (any vs tenant-specific)
- Suggested test approach (CLI/Playwright/Manual)
- Manual verification steps (e.g., "Review the AlertMagic diagram and confirm layout matches specification")
- Test execution checklist

**Immediate Win:** QA engineers start each day with a pre-sorted list. Easy, any-environment tickets get picked up first. Tenant-specific ones get flagged for special setup.

---

### 2. **Smoke Test Generator** (Deploy This Week)
**What:** For UI-testable tickets, AI generates a minimal Playwright smoke test based on the ticket description.

**Process:**
1. Read ticket description + acceptance criteria from JIRA
2. Identify the affected page/component from labels or description
3. Generate a targeted Playwright test that:
   - Navigates to the page
   - Checks element exists/works as described
   - Takes before/after screenshots
   - Auto-comments result back to JIRA

**New Tool: `Generate-SmokeTest.ps1`**
```powershell
# Example usage
.\scripts\Generate-SmokeTest.ps1 -IssueKey MS-22886 -Environment test2

# Outputs: playwright/Magic Suite/Generated/ms-22886-smoke.spec.ts
```

**Template Generation Logic:**
- If "button" in description → Generate click + visibility test
- If "error message" in description → Generate error state verification
- If "dark mode" in description → Generate theme toggle + screenshot test
- If "API" in description → Generate CLI verification test

**Immediate Win:** 30-50% of "Easy" Playwright tickets could be auto-verified in under 2 minutes each.

---

### 3. **Log-Based Regression Detection** (Deploy This Week)
**What:** Use Elastic.ps1 to proactively check for new errors related to a ticket's component BEFORE QA starts testing.

**Process:**
1. Before testing a ticket, query Elastic for errors related to the component in the last 7 days
2. Compare error patterns to before the fix was deployed
3. Auto-flag tickets where:
   - New errors appeared after the fix version
   - Related component has high error rates
   - Specific exception types match the bug

**New Elastic.ps1 Action: `RegressionCheck`**
```powershell
.\.github\tools\Elastic.ps1 -Action RegressionCheck -Parameters @{
    IssueKey = "MS-22886"
    Component = "ReportStudio"
    FixVersion = "4.1.691"
    DaysToCheck = 7
}

# Output:
# ✓ No new errors detected for ReportStudio since 4.1.691
# ✓ Error rate decreased by 23% post-fix
# → Recommend: Quick smoke test only
```

**Immediate Win:** Tickets with clean Elastic logs can be fast-tracked. Tickets with new errors get flagged for deeper investigation before QA wastes time.

---

### 4. **CLI Command Fuzzing & Verification** (Deploy Today)
**What:** For CLI-related tickets, automatically run the CLI command with various inputs and verify exit codes + output format.

**Already Have:** `test-scripts/CLI/` structure with Core, API, ExitCodes, Output folders.

**Enhancement: `Auto-VerifyCLI.ps1`**
```powershell
# Reads ticket description, extracts CLI commands mentioned, runs them
.\scripts\Auto-VerifyCLI.ps1 -IssueKey MS-22611 -Profile test2

# Does:
# 1. Extracts "take parameter" from description
# 2. Runs: magicsuite api get tenants --take -1
# 3. Checks exit code (should be non-zero for invalid input)
# 4. Runs with valid inputs as control
# 5. Reports pass/fail with evidence to JIRA
```

**Pattern Matching:**
- "exit code" → Run command, verify $LASTEXITCODE
- "output format" → Run with --format Json, validate JSON
- "error message" → Capture stderr, verify contains expected text
- "timeout" → Run with --timeout, verify behavior

**Immediate Win:** CLI bugs can often be verified in <30 seconds with scripted tests. No Playwright overhead.

---

### 5. **Screenshot Diff for Visual Bugs** (Deploy This Week)
**What:** For UI tickets mentioning colors, alignment, icons, or visual changes, automatically capture before/after screenshots and highlight differences.

**Process:**
1. Use Playwright to navigate to affected page
2. Capture screenshot in light mode and dark mode
3. Compare to baseline (if exists) or to production
4. Highlight visual differences
5. Attach comparison images to JIRA

**New Tool: `Visual-Verify.ps1`**
```powershell
.\scripts\Visual-Verify.ps1 -IssueKey MS-22886 -Page "/report-studio" -Environment test2

# Outputs:
# - screenshots/ms-22886-test2-dark.png
# - screenshots/ms-22886-test2-light.png  
# - screenshots/ms-22886-diff.png (highlighted differences)
```

**Integration with Playwright:**
```typescript
// Auto-generated comparison test
test('MS-22886: Visual regression check', async ({ page }) => {
  await page.goto('https://test2.magicsuite.net/report-studio');
  await page.locator('[data-testid="theme-toggle"]').click(); // dark mode
  
  await expect(page).toHaveScreenshot('ms-22886-dark-mode.png', {
    maxDiffPixels: 100
  });
});
```

**Immediate Win:** Visual bugs often take 10+ minutes to verify manually. Automated screenshot capture + diff takes <1 minute.

---

### 6. **Ticket Quality Assessment** (Deploy Today)
**What:** Before testing, assess the quality and completeness of the ticket specification to identify gaps that will slow down testing or cause ambiguity.

**Quality Factors Assessed:**

| Factor | Weight | What We Check |
|--------|--------|---------------|
| **Component Identified** | 15% | Is there a JIRA component? Does description mention a specific app? |
| **Description Completeness** | 20% | Length, detail level, context provided |
| **Testability** | 20% | Clear pass/fail criteria, measurable outcome |
| **Steps to Reproduce** (bugs) | 15% | Numbered steps, specific actions, data requirements |
| **Current vs Expected** (bugs) | 15% | Both behaviors clearly stated |
| **Environment/Version** | 10% | Fix version specified, environment mentioned |
| **Attachments/Evidence** | 5% | Screenshots, logs, or examples attached |

**New Tool: `Assess-TicketQuality.ps1`**
```powershell
.\scripts\Assess-TicketQuality.ps1 -IssueKey MS-22886

# Output:
# ╔═══════════════════════════════════════════════════════════╗
# ║  TICKET QUALITY ASSESSMENT: MS-22886                      ║
# ╠═══════════════════════════════════════════════════════════╣
# ║  Overall Score: 72/100 - ADEQUATE                         ║
# ╠═══════════════════════════════════════════════════════════╣
# ║  ✓ Component: ReportMagic (identified)                    ║
# ║  ✓ Description: 156 words (adequate)                      ║
# ║  ⚠ Testability: No clear acceptance criteria              ║
# ║  ✓ Steps to Reproduce: 4 steps found                      ║
# ║  ✓ Current vs Expected: Both documented                   ║
# ║  ✓ Fix Version: 4.1.691                                   ║
# ║  ⚠ Attachments: None                                      ║
# ╠═══════════════════════════════════════════════════════════╣
# ║  RECOMMENDATIONS:                                         ║
# ║  • Request acceptance criteria from developer             ║
# ║  • Ask for screenshot of expected behavior                ║
# ╚═══════════════════════════════════════════════════════════╝
```

**Batch Assessment:**
```powershell
# Assess all Ready for Test tickets and flag poor quality ones
.\scripts\Assess-TicketQuality.ps1 -BatchMode -MinScore 60

# Output: List of tickets below threshold with missing elements
```

**Integration with Triage:**
- Tickets scoring < 50 get label `ai-needs-clarification`
- Tickets scoring < 30 get auto-commented requesting more info
- QA can filter to only work on well-specified tickets

**Immediate Win:** 
- QA stops wasting time on ambiguous tickets
- Developers learn what good specifications look like
- Reduces back-and-forth clarification cycles

---

## 📊 Estimated Impact

| Technique | Tickets Affected | Time Saved Per Ticket | Total Savings |
|-----------|-----------------|----------------------|---------------|
| Auto-Triage | All 380 | 5 mins (decision time) | ~30 hours |
| Smoke Generator | ~100 Easy Playwright | 8 mins each | ~13 hours |
| Log-Based Regression | All 380 | 3 mins (pre-check) | ~19 hours |
| CLI Fuzzing | ~50 CLI tickets | 10 mins each | ~8 hours |
| Screenshot Diff | ~80 visual tickets | 8 mins each | ~10 hours |
| Ticket Quality | All 380 | 5 mins (avoids rework) | ~30 hours |

**Conservative Total: ~110 hours saved** from current backlog processing.

---

## 🚀 Implementation Priority

### Deploy Today (2-4 hours each)
1. **Auto-Triage enhancement** - Add label-applying to JIRA.ps1
2. **CLI Fuzzing** - Enhance existing test-scripts with auto-extraction
3. **Ticket Quality Assessment** - Pattern-based spec quality scoring

### Deploy This Week (4-8 hours each)
4. **Smoke Test Generator** - Template-based Playwright generation
5. **Log-Based Regression** - Add RegressionCheck to Elastic.ps1
6. **Screenshot Diff** - Playwright visual comparison setup

---

## 🔧 New Scripts to Create

### 1. `scripts/Auto-Triage.ps1`
- Query JIRA for Ready for Test tickets
- Use AI (via Claude API or pattern matching) to categorize
- Apply labels to JIRA
- Generate daily report

### 2. `scripts/Generate-SmokeTest.ps1`
- Take issue key as input
- Fetch ticket details
- Generate Playwright test file
- Run test and report results

### 3. `scripts/Auto-VerifyCLI.ps1`
- Extract CLI commands from ticket
- Run with various inputs
- Verify exit codes and output
- Post results to JIRA

### 4. `scripts/Visual-Verify.ps1`
- Navigate to page in both themes
- Capture screenshots
- Run pixel diff comparison
- Attach results to JIRA

### 5. `scripts/Pre-Test-Check.ps1` (combines techniques)
- Runs Elastic regression check
- Runs appropriate auto-verification based on ticket type
- Produces a "readiness report" for QA engineer

### 6. `scripts/Assess-TicketQuality.ps1`
- Analyze ticket specification completeness
- Score based on testability factors
- Flag tickets needing clarification
- Optionally request more info via JIRA comment

---

## 💡 Key Principles

1. **Don't Replace QA - Accelerate Them**
   - AI handles the repetitive verification
   - Humans focus on exploratory testing and edge cases

2. **Fail Fast**
   - If auto-tests fail, escalate immediately
   - Don't waste QA time on broken builds

3. **Evidence Everything**
   - Every automated action posts evidence to JIRA
   - Full audit trail for compliance

4. **Start Simple**
   - Pattern matching > Complex ML
   - Template generation > AI code generation
   - Known paths > Dynamic discovery

5. **Measure & Iterate**
   - Track tickets processed per day before/after
   - Measure accuracy of auto-categorization
   - Adjust thresholds based on feedback

---

## 📋 Ticket Categories (Reference)

From current analysis:
- **CLI Testable**: 1 ticket (pattern: exit codes, output format, commands)
- **Playwright Testable**: 32 tickets (pattern: UI, buttons, modals, visual)
- **Both CLI & Playwright**: 17 tickets (pattern: API + UI verification needed)
- **Manual Required**: ~30+ tickets (pattern: complex integrations, external systems)

---

**Next Step:** Start with Technique #1 (Auto-Triage) and #4 (CLI Fuzzing) - these can be deployed with minimal new code by enhancing existing tools.
