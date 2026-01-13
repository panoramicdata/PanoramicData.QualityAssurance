# Copilot Instructions for Panoramic Data Quality Assurance

## 📋 Table of Contents
1. [🎯 Critical Rules](#-critical-rules) - **READ FIRST**
2. [👥 Team Information](#-team-information)
3. [🛠️ Available Tools](#️-available-tools)
4. [🧪 Testing Requirements](#-testing-requirements)
5. [📝 Workflow Guidelines](#-workflow-guidelines)
6. [🔧 MagicSuite CLI Reference](#-magicsuite-cli-reference)

---

# 🎯 Critical Rules

## ⚠️ MUST-FOLLOW Rules (Always Check These First)

### 1. Test Environment Confirmation
- **ALWAYS confirm environment BEFORE running tests**: alpha, alpha2, test, test2, beta, staging, production
- Explicitly state: "I will run this test on **test2** environment"
- Wait for confirmation if ambiguous
- Never assume - always verify first

### 2. MagicSuite CLI Version
- **ONLY use 4.1.x versions** for official testing
- **NEVER use 4.2.x** for bug testing and JIRA updates
- Verify version: `magicsuite --version`
- To switch: `dotnet tool uninstall magicsuite.cli -g; dotnet tool install magicsuite.cli -g --version 4.1.*`

### 3. Playwright Browser Testing
- **ALWAYS specify `--project=firefox`** (preferred) or `--project=chromium`
- **WITHOUT --project flag, ALL browsers open at once**
- Use test names, NOT file paths: ✅ `auth.setup` ❌ `"Magic Suite\auth.setup.spec.ts"`
- Example: `npx playwright test auth.setup --headed --project=firefox`

### 4. Tool Script Usage
- **JIRA**: ALWAYS use `.github/tools/JIRA.ps1` - NEVER direct REST API (except for full bug creation)
- **XWiki**: ALWAYS use `.github/tools/XWiki.ps1` - NEVER direct REST API
- **Extend scripts** when functionality is missing (don't work around them)

### 5. JIRA Workflow Updates
- Post progress comments at key milestones
- Transition tickets appropriately: Ready for Progress → In Progress → Ready for Test → In Test
- Always include environment and version info in test results
- Link related issues and artifacts

---

# Copilot Instructions for Panoramic Data Quality Assurance Team

---

# 👥 Team Information

## Quality Assurance Team
- **Amy Bond** (`amy.bond`) - QA focused on testing and automation
- **Claire Campbell** (`claire.campbell`) - QA with testing assignments
- **Sam Walters** (`sam.walters`) - Testing activities, "In Test" and "Ready for Test" status

## Magic Suite Development Team
**Main Developers:**
- **Roland Banks** (`roland.banks`) - API/backend, critical/blocker issues
- **John Odlin** (`john.odlin`) - UI/Frontend, DataMagic and AlertMagic

**Additional Developers:**
- **David Bond** (`david.bond`)
- **Daniel Abbott**

## Key Application Components
- **DataMagic** - Database and data visualization
- **AlertMagic** - Alerting and notification system
- **Files UI** - File management (SharePoint integration)
- **Estate Tree** - Navigation and hierarchy

## JIRA Project
- **Project Key**: MS (Magic Suite) - 4200+ issues
- **JIRA URL**: https://jira.panoramicdata.com
- **Workflow**: Ready for Progress → In Progress → Ready for Test → In Test

---

# 🛠️ Available Tools

## JIRA Integration (`.github/tools/JIRA.ps1`)
| Action | Description | Required Parameters | Notes |
|--------|-------------|---------------------|-------|
| `Get` | Get issue details | `-IssueKey` | Basic issue info |
| `GetFull` | Get issue with comments/history | `-IssueKey` | Includes comments and changelog |
| `Detailed` | Get comprehensive formatted info | `-IssueKey` | Formatted summary |
| `Search` | Search issues by JQL | `-Parameters @{JQL="..."}` | |
| `Create` | Create new issue | `-Parameters @{ProjectKey, IssueType, Summary, Description}` | Limited - see note below |
| `Update` | Update issue fields | `-IssueKey`, `-Parameters @{Fields=@{...}}` | |
| `Comment` | Add comment | `-IssueKey`, `-Parameters @{Comment="..."}` | |
| `Transition` | Change issue status | `-IssueKey`, `-Parameters @{TransitionName="..."}` | |
| `Team` | Get team member issues | | QA team filtering |

**IMPORTANT - Creating JIRA Tickets:**
- The `Create` action in JIRA.ps1 has **limitations**: it doesn't support labels, priority, custom fields (like customfield_11200), or issue links
- **When creating bug tickets** that need these fields:
  1. **First choice**: Extend JIRA.ps1 by adding an enhanced `New-JiraIssueFull` function that supports all fields
  2. **Temporary workaround**: Use direct REST API calls BUT document this as technical debt
  3. **Always use environment variables** for credentials (`$env:JIRA_USERNAME`, `$env:JIRA_PASSWORD`)
  4. **Never use `Get-StoredCredential`** - it's not universally available

**Common Pitfalls When Creating Tickets:**
1. **Ampersand character** in strings like `"MagicSuite_R&D"` must be in single quotes: `@('MagicSuite_R&D')`
2. **Here-string syntax** (@"..."@) inside hashtables can cause parsing errors - use single-quoted strings with concatenation instead
3. **Required custom field**: `customfield_11200 = @('MagicSuite_R&D')` is required for MS project tickets
4. **Priority**: Use `@{id = "2"}` for Critical, `@{id = "3"}` for High, etc.
5. **Labels**: Must be array of strings: `@("CLI", "exit-codes", "automation-blocker")`

**Example - Creating a Comprehensive Bug Ticket:**
```powershell
# Get credentials from environment
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Use simple string variable for description (avoid here-strings in hashtables)
$description = 'h2. Summary
Bug description here

h2. Environment
* CLI Version: 4.1.323
* Test Date: 2025-12-18'

# Create issue with all required fields
$issue = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "Brief description"
        description = $description
        priority = @{id = "2"}  # Critical
        labels = @("CLI", "exit-codes")
        customfield_11200 = @('MagicSuite_R&D')  # Required for MS project
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
    -Method POST -Headers $headers -Body $issue
```

### Elastic Integration (`tools/Elastic.ps1`)
- Connects to Elastic cluster using environment variables
- Required environment variables:
  - `ELASTIC_USERNAME` - Your Elastic username
  - `ELASTIC_PASSWORD` - Your Elastic password
- Elastic URL: `https://pdl-elastic-prod.panoramicdata.com`

### XWiki Integration (`tools/XWiki.ps1`)
- **Purpose**: Access and manage company wiki pages
- **CRITICAL**: Copilot/AI assistants must ALWAYS use this script to interact with XWiki. NEVER access the XWiki REST API directly.
- **Credentials**: Windows Credential Manager (target: `LogicMonitor:XWiki`)
- **XWiki URL**: `https://wiki.panoramicdata.com`

**Available Actions:**
| Action | Description | Required Parameters |
|--------|-------------|---------------------|
| `Read` | Parse page from URL (extracts tables) | `-Url` |
| `Get` | Get page metadata + content as JSON | `-Space` |
| `GetContent` | Get ONLY the page content (string) | `-Space` |
| `Create` | Create a new wiki page | `-Space`, `-PageName`, `-Title`, `-Content` |
| `Update` | Update existing page content | `-Space`, `-Content` or `-Title` |
| `Replace` | Find and replace text in a page | `-Space`, `-Find`, `-Replace` |
| `Delete` | Delete a page | `-Space` |
| `Search` | Search for pages by keyword | `-Query` |
| `ListSpaces` | List all wiki spaces | (none) |

**Common Usage Examples:**
```powershell
# Read the QA Home page
.\.github\tools\XWiki.ps1 -Action GetContent -Space "QA Home"

# Read a nested page (use dots to separate nested spaces)
.\.github\tools\XWiki.ps1 -Action GetContent -Space "QA Home.QA's AI hopes, dreams and plans"

# Fix a typo on a page
.\.github\tools\XWiki.ps1 -Action Replace -Space "QA Home" -Find "typo" -Replace "correction"

# Search for pages about regression testing
.\.github\tools\XWiki.ps1 -Action Search -Query "regression"

# Create a new test documentation page
.\.github\tools\XWiki.ps1 -Action Create -Space "QA Home" -PageName "TestDoc" -Title "Test Documentation" -Content "# Test Doc"
```

**Nested Spaces:**
- Use dots (`.`) to separate nested space names
- Example: `"QA Home.SubSpace.DeepSpace"` → navigates to QA Home → SubSpace → DeepSpace
- Default page in any space is `WebHome`

### Playwright MCP Integration (`playwright/`)
- **Purpose**: AI-assisted browser automation for UI testing
- **Documentation**: See `playwright/README.md` for full setup instructions
- **Configuration**: Add to `.vscode/mcp.json` to enable Playwright MCP tools
- **Browser Preference**: **ALWAYS use Firefox as the default browser** for Playwright tests. Chromium can be used if specifically required or if Firefox fails.
- **Key Features**:
  - Navigate to web pages and interact with UI elements
  - Capture screenshots for bug documentation
  - Record traces for detailed debugging
  - Cross-browser testing (Chrome, Firefox, WebKit, Edge)
  - Device emulation for mobile testing
- **Quick Setup**:
  1. Create `.vscode/mcp.json` in workspace
  2. Add Playwright server configuration
  3. Restart VS Code to activate MCP tools
- **Example MCP Configuration**:
  ```json
  {
    "servers": {
      "playwright": {
        "command": "npx",
        "args": ["@playwright/mcp@latest", "--browser", "firefox", "--cap", "vision"]
      }
    }
  }
  ```
- **Task-Specific Instructions**: See `.github/playwright-instructions.md` for Magic Suite URL patterns, environments, and test conventions

**CRITICAL - Running Playwright Tests:**
- **ALWAYS specify a project** when running Playwright tests to avoid opening multiple browsers simultaneously
  - Use `--project=firefox` (preferred default) or `--project=chromium`
  - Example: `npx playwright test auth.setup --headed --project=firefox`
  - **WITHOUT `--project` flag, ALL configured browsers will open at once**
- **Use test name patterns, NOT file paths**:
  - ✅ Correct: `npx playwright test auth.setup`
  - ❌ Wrong: `npx playwright test "Magic Suite\auth.setup.spec.ts"`
  - Playwright matches test names, not file paths
- **Browser preference**: Always use `--project=firefox` unless specifically requested otherwise

**CRITICAL - Tests Requiring Authentication:**
- When creating or running Playwright tests that require login, **ALWAYS allow sufficient time for manual login**
- Magic Suite apps require authentication - tests must either:
  1. Use saved auth state from `.auth/user.json` (run `npx playwright test auth.setup --headed --project=firefox` first)
  2. Include a `page.pause()` to allow manual login before proceeding
- **When running tests that need login**:
  - Run auth.setup FIRST as a separate step: `npx playwright test auth.setup --headed --project=firefox`
  - Wait for the user to complete login before running the actual tests
  - Set generous timeouts (5+ minutes) for manual login steps
- **When creating new authenticated tests**:
  - Add a `beforeEach` hook that checks for auth redirect
  - Include helpful error messages directing user to run auth.setup
  - Consider adding `test.setTimeout(300000)` (5 min) for tests requiring manual intervention
- **NEVER immediately run authenticated tests** without first confirming the auth state exists or giving time for login

### Regression Test Runner (`tools/RunRegressionTests.ps1`)
- **Purpose**: Run Playwright regression tests against Magic Suite environments
- **Usage**:
  ```powershell
  # Run all tests on alpha
  .\.github\tools\RunRegressionTests.ps1 -Environment alpha
  
  # Run specific app tests
  .\.github\tools\RunRegressionTests.ps1 -Environment staging -Apps AlertMagic,DataMagic
  
  # Run with visible browser
  .\.github\tools\RunRegressionTests.ps1 -Environment test -Headed
  ```
- **Environments**: alpha, alpha2, test, test2, beta, staging, ps, production

## Test Plans and Documentation

### Test Plan Locations
Test plans are organized in the following structure:
- **Main Test Plans**: `test-plans/` directory in project root
- **Naming Convention**: `MS-12345.md` format matching JIRA issue keys
- **Template Available**: `test-plans/README.md` contains structure guidelines
- **Automated Test Scripts**: `[PLACEHOLDER_AUTOMATED_TESTS_PATH]`
- **Test Data**: `[PLACEHOLDER_TEST_DATA_PATH]`
- **Test Results Archive**: `[PLACEHOLDER_TEST_RESULTS_PATH]`

### Documentation Standards
- All test plans should follow the established template format
- Test results must be documented with timestamps and environment details
- Bug reports should include reproduction steps and system information

## Guidance for Merlin (AI Assistant)

### When Assisting with QA Tasks:

1. **Always ask clarifying questions** before proceeding with:
   - Test plan modifications
   - Test execution strategies
   - Environment-specific configurations
   - Data manipulation or cleanup

2. **Common clarifying questions to ask**:
   - Which environment should be targeted (dev/staging/production)?
   - What is the expected timeline for test execution?
   - Are there any specific regression areas to focus on?
   - Should automated tests be included or only manual testing?
   - What is the priority level of the testing (critical/high/medium/low)?
   - Are there any known issues or blockers to be aware of?
   - What browsers/devices need to be included in testing?
   - Should performance testing be included?
   - Is this related to the Magic Suite project or other systems?

3. **Before making changes**:
   - Confirm the scope of work with team members
   - Verify access to required systems and environments
   - Check for any ongoing testing that might be impacted
   - Ensure backup procedures are in place for critical test data

4. **When working with JIRA**:
   - **ALWAYS use the JIRA.ps1 script** for all JIRA interactions - never use direct API calls or other methods
   - **EXCEPTION**: When creating comprehensive bug tickets with labels, priority, and custom fields, the current JIRA.ps1 Create action is limited. In this case:
     - **Preferred**: Extend JIRA.ps1 with a `New-JiraIssueFull` function that supports all fields
     - **Temporary**: Use direct REST API with environment variables (`$env:JIRA_USERNAME`, `$env:JIRA_PASSWORD`)
     - **Never use** `Get-StoredCredential` - it's not universally available
   - **When creating tickets via REST API**:
     - Store description in a variable BEFORE the hashtable (avoid here-strings inside hashtables)
     - Use single quotes for strings with ampersands: `@('MagicSuite_R&D')`
     - Always include `customfield_11200 = @('MagicSuite_R&D')` for MS project tickets
     - Priority must be object with id: `@{id = "2"}` for Critical
     - Labels must be array: `@("CLI", "exit-codes")`
   - **Update tickets proactively** with progress comments throughout work sessions
   - **Transition tickets through workflows** when appropriate (Ready for Progress → In Progress → Ready for Test → In Test)
   - Always verify issue status before making changes
   - Include relevant team members in ticket updates
   - Follow the established workflow states (Ready for Progress → In Progress → Ready for Test → In Test)
   - Link related issues appropriately
   - Use the JIRA tool to enumerate users and analyze ticket patterns to understand team roles
   - **Extend the JIRA.ps1 script** as needed by adding new functions and actions when you encounter requirements that aren't currently supported
   - When adding new capabilities, update the help text and examples in the script's default action

5. **JIRA Progress Tracking & Workflow Management**:
   - **At Start of Work**: Always check current ticket status and add comment about starting work
   - **During Work**: Post progress updates at key milestones (e.g., "Test plan created", "Logs collected", "Analysis complete")
   - **Workflow Transitions**: 
     - Move tickets from "Ready for Progress" → "In Progress" when starting work
     - Move from "In Progress" → "Ready for Test" when QA work is complete and ready for developer testing
     - Move from "Ready for Test" → "In Test" when actively executing test cases
     - Always add comments explaining the reason for transition
   - **Progress Comments Should Include**:
     - Summary of work completed
     - Key findings or results
     - Links to created artifacts (test plans, log files, reports)
     - Next steps or handoff information
     - Any blockers or issues discovered
   - **Comment Examples**:
     ```
     "Started analysis of MS-21863. Created comprehensive test plan with 6 test cases covering SharePoint regression between v3.26.501 and v3.27.351. Collected 1.25MB of logs from Elastic for analysis. Moving to In Progress."
     
     "Progress Update: Analyzed collected logs and found version info (3.28.163 detected). No 'not found' errors found in current log sample. Recommend expanding search to error-specific indices. Test plan ready for execution."
     
     "QA work complete. Test plan created, logs collected and analyzed, environment setup documented. Ready for developer review and test execution. Moving to Ready for Test."
     ```
   - **When to Transition**:
     - **Ready for Progress → In Progress**: When you start working on the ticket
     - **In Progress → Ready for Test**: When QA preparation is complete (test plans, environment setup, log analysis)
     - **Ready for Test → In Test**: When actively executing test cases or validating fixes
     - **In Test → Closed/Resolved**: When testing is complete and results documented

6. **CRITICAL - Test Environment Confirmation**:
   - **ALWAYS confirm the test environment BEFORE running any test**
   - **Magic Suite Environments**: alpha, alpha2, test, test2, beta, staging, production
   - **Before executing tests**:
     - Ask user which environment to test if not specified
     - Explicitly state the environment in your response: "I will run this test on **test2** environment"
     - Wait for confirmation if there's any ambiguity
   - **Common environment patterns**:
     - Default for QA testing: **test2** (unless specified otherwise)
     - Check `MS_ENV` environment variable or `.auth/user.json` for current auth state
     - MagicSuite CLI profiles contain environment-specific API URLs
   - **Example confirmation**: 
     - "I'll run this Playwright test on the **test2** environment. Please confirm before I proceed."
     - "This CLI test will use the **AmyTest2** profile (test2 environment). Is this correct?"
   - **Never assume an environment** - always verify and confirm first

7. **JIRA.ps1 Script Enhancement Guidelines**:
   - **Current capabilities**: get, search, create, update, comment, transition, team actions
   - **Enhanced ticket access**: getfull, detailed, comments, history actions for comprehensive ticket information
   - **Ticket data includes**: All comments, state transitions, change history, and formatted summaries
   - **Add new functions** when you need capabilities not currently available
   - **Follow the existing pattern**: Add a new function, then add a new case in the switch statement
   - **Update the help text** in the default action when adding new functionality
   - **Test new functions** before using them in production workflows
   - **Document new parameters** and provide usage examples
   - **Common extensions needed**: bulk operations, advanced filtering, reporting functions, user management

8. **When working with Elastic**:
   - Be cautious with query operations on production data
   - Use appropriate time ranges to avoid performance impact
   - Verify index patterns before executing searches
   - Document any custom queries for future reference

10. **When working with XWiki**:
   - **ALWAYS use the XWiki.ps1 script** for all wiki interactions - NEVER access the XWiki REST API directly
   - **Extend XWiki.ps1** if new functionality is needed rather than using direct API calls
   - **Use `GetContent`** action when you need to read page content for analysis or editing
   - **Use `Replace`** action for fixing typos or small text changes (avoids needing full content)
   - **Use `Update`** action for replacing entire page content
   - **Nested spaces**: Use dots to separate space hierarchy (e.g., `"QA Home.SubSpace"`)
   - **Default page**: If `-PageName` is not specified, defaults to `WebHome` (the main page of a space)
   - **Common wiki pages**:
     - QA documentation: `-Space "QA Home"`
     - QA AI plans: `-Space "QA Home.QA's AI hopes, dreams and plans"`
   - **Before editing wiki content**:
     - Read the existing content first with `GetContent`
     - Verify you have the correct page/space
     - For typos, prefer `Replace` action over `Update`
   - **XWiki.ps1 Enhancement Guidelines**:
     - Follow existing patterns when adding new actions
     - Use `Build-XWikiPageUrl` helper for constructing API URLs
     - Update the header examples when adding new functionality
     - Test new functions before using in production

8. **When working with Playwright MCP**:
   - **Check if Playwright MCP tools are available** before attempting browser automation
   - **Use for UI testing** when testing Magic Suite web interfaces (AlertMagic, DataMagic, Files UI)
   - **Capture screenshots** when documenting bugs or test results
   - **Record traces** for complex test scenarios that need detailed playback
   - **Common use cases**:
     - Verifying UI displays correctly after bug fixes
     - Testing form submissions and user interactions
     - Cross-browser compatibility testing
     - Mobile device emulation testing
   - **If Playwright MCP tools are not available**:
     - Check if `.vscode/mcp.json` exists with Playwright configuration
     - Verify Node.js is installed (`node --version`)
     - Run `npx @playwright/mcp@latest --help` to test CLI availability
     - See `playwright/README.md` for setup instructions
   - **When capturing evidence for JIRA**:
     - Save screenshots to `playwright/screenshots/`
     - Save traces to `playwright/traces/`
     - **Video recordings**: Playwright automatically records all tests in WebM format (configured in playwright.config.ts)
     - **CRITICAL**: When uploading videos to JIRA, the file MUST have the `.webm` extension or JIRA will reject the upload
     - Videos are saved to `playwright/test-results/<test-name>/video.webm`
     - If downloading from Playwright HTML report and file saves without extension, manually add `.webm` before uploading to JIRA
     - Reference captured files in JIRA comments

9. **Standard QA Workflow Integration with JIRA**:
   - **Always start QA work** by updating the JIRA ticket with a progress comment
   - **Before creating test plans**: Add comment about starting test plan creation
   - **After creating test plans**: Add comment with link to test plan file and summary
   - **Before collecting logs**: Add comment about starting log collection for analysis
   - **After collecting logs**: Add comment with summary of logs collected, file sizes, and key findings
   - **During analysis**: Add progress comments for significant findings or roadblocks
   - **After completing analysis**: Add comprehensive comment with findings and recommendations
   - **Before transitioning**: Always add a comment explaining the reason for the status change
   - **When syncing to repository**: Add comment about committing work with commit hash if available
   - **When commenting on test results**: ALWAYS include test environment and version information:
     - Test environment (e.g., test2.magicsuite.net, alpha.magicsuite.net)
     - Application version (e.g., v4.1.275)
     - Test date/time
     - Test framework and browser versions (for automated tests)
     - Example: "Environment: test2.magicsuite.net (DataMagic), Version: v4.1.275, Test Date: 2025-12-15 16:36:09, Browsers: Chromium 143.0.7499.4, Firefox 144.0.2"
   - **Example Standard Workflow Comments**:
     - Start: "Beginning QA work on MS-21863 SharePoint regression. Creating test plan and collecting logs for analysis."
     - Test Plan: "Created comprehensive test plan (MS-21863.md) with 6 test cases covering version comparison and SharePoint file operations. Ready to collect supporting logs."
     - Log Collection: "Collected 1.25MB of logs from Elastic (SharePoint: 529KB, CAE Agent: 726KB). Found version info and connection details. Starting analysis."
     - Analysis: "Log analysis complete. Found version 3.28.163 in current environment. No critical 'not found' errors in sample. Test plan ready for execution."
     - Completion: "QA preparation complete. Test plan created, logs collected and analyzed, documentation updated. Ready for test execution or developer review."

### Self-Improvement and Evolution

**Merlin should continuously evolve these instructions:**
- **Learn from patterns**: Analyze JIRA ticket creation/update patterns to understand team member roles
- **Identify new needs**: When encountering new requirements or workflows, update these instructions
- **Add new tools**: Create additional PowerShell tools or scripts as needed for team efficiency
- **Update team information**: Keep team member lists and roles current based on JIRA analysis
- **Refine guidance**: Improve clarifying questions and best practices based on experience
- **Enhance JIRA.ps1**: Continuously add new functions and capabilities to the JIRA tool as requirements emerge
- **Enhance XWiki.ps1**: Add new actions to XWiki.ps1 as wiki interaction needs evolve (never use direct API calls)
- **Document improvements**: Update the copilot instructions whenever new capabilities are added to tools

### Security Considerations

- Never commit actual credentials to the repository
- Use environment variables for all authentication
- Verify SSL/TLS settings for external connections
- Follow company security policies for data access

### Best Practices

1. **Code Reviews**: All scripts should be reviewed by at least one team member
2. **Version Control**: Use descriptive commit messages and branch naming
3. **Testing**: Test all scripts in non-production environments first
4. **Documentation**: Keep this file updated as processes evolve
5. **Monitoring**: Set up appropriate logging for automated processes

## Emergency Contacts

For urgent issues outside normal business hours:
- Escalation procedures: `[PLACEHOLDER_ESCALATION_PROCESS]`
- On-call contacts: `[PLACEHOLDER_ONCALL_CONTACTS]`

## Environment Information

### Development Environment
- JIRA Instance: `[PLACEHOLDER_DEV_JIRA_URL]`
- Elastic Cluster: `[PLACEHOLDER_DEV_ELASTIC_URL]`

### Staging Environment
- JIRA Instance: `[PLACEHOLDER_STAGING_JIRA_URL]`
- Elastic Cluster: `[PLACEHOLDER_STAGING_ELASTIC_URL]`

### Production Environment
- JIRA Instance: `[PLACEHOLDER_PROD_JIRA_URL]`
- Elastic Cluster: `[PLACEHOLDER_PROD_ELASTIC_URL]`

---

**Last Updated**: December 2025  
**Maintained By**: Panoramic Data QA Team  
**Version**: 1.1

---

# MagicSuite CLI Tool - Reference Guide

## Overview
MagicSuite CLI (command: `magicsuite`) is a command-line interface for Magic Suite operations. It provides comprehensive API access and management capabilities for the Magic Suite platform.

**Version**: 4.1.278+0db90d0a24  
**Installation Location**: `C:\Users\amycb\.dotnet\tools\magicsuite.exe`

## Global Options
Available across all commands:
- `--profile <profile>` - Use named profile (e.g., production, alpha3, local)
- `--api-url <api-url>` - Override API URL from profile/config
- `--token-name <token-name>` - Override API token name
- `--token-key <token-key>` - Override API token key
- `--tenant <tenant>` - Tenant three-letter code, ID, or GUID (overrides default)
- `--format <Json|Table>` - Output format (json or table) [default: Table]
- `--output <output>` - Write output to file instead of console
- `--verbose` - Enable verbose logging
- `--quiet` - Suppress non-essential output
- `--include-all-tenants` - Include all tenants (SuperAdmin only)
- `--version` - Show version information
- `-?, -h, --help` - Show help and usage information

## Main Commands

### 1. `config` - Manage CLI Configuration and Profiles
Manages environment profiles and configuration settings.

**Subcommands:**
- `profiles` - Manage environment profiles
- `set <key> <value>` - Set a configuration value
- `get <key>` - Get a configuration value
- `list` - List all configuration settings
- `init` - Interactive configuration wizard

### 2. `auth` - Manage Authentication Credentials
Handles authentication and credential management.

**Subcommands:**
- `token` - Set API token credentials
- `status` - Show current authentication status
- `logout` - Clear authentication credentials

### 3. `api` - Perform CRUD Operations on Magic Suite Entities
Core API operations for working with Magic Suite entities via REST API.

**Subcommands:**
- `get` - List entities with filtering and pagination
- `get-by-id` - Get a single entity by its ID
- `patch` - Update specific properties of an entity
- `delete` - Delete an entity by ID

**Examples:**
```powershell
magicsuite api get tenants
magicsuite api get connections --filter Logic
magicsuite api get reportschedules --select Id,Name,Enabled
magicsuite api get-by-id tenant 1
magicsuite api patch tenant 1 --set Name="New Name"
magicsuite api delete tenant 1
```

**Supported Entity Types** (119 total):
AgeingEvent, AntiForgeryToken, ApiInfo, ApiToken, AuditLog, Badge, BillableActivity, BloggerPost, CachedValue, Case, CaseFile, CaseGitCommit, CaseNote, CaseProject, CaseProjectCaseAssignmentRule, CaseProjectCaseCategory, CaseProjectCaseSubCategory, CaseProjectComponent, CaseProjectComponentAssociation, CaseProjectEnvironment, CaseProjectNotificationRule, CaseRelationship, CaseSprint, CaseWorkflow, CaseWorkflowCustomCaseField, CaseWorkflowRelationshipType, CaseWorkflowResolution, CaseWorkflowState, CaseWorkflowStateTransition, CaseWorkflowStateTransitionField, CaseWorkflowStateTransitionScreen, CaseWorkflowSymbol, CaseWorkflowType, Certification, CertificationAnswerOption, CertificationQuestion, CertificationSession, CertificationSessionAnswer, CertificationTopic, Connection, ConnectionRole, Dashboard, DashboardTab, DashboardTabTile, DataMagicSync, DataMagicSyncExecution, DocMagicStatusInfo, EventManager, EventManagerAction, EventManagerAlertManagementSystem, EventManagerCalculation, EventManagerConstant, EventManagerDeduplicationFieldTransformation, EventManagerDeduplicationMapping, EventManagerIncidentCommentSpec, EventManagerIncidentManagementSystem, EventManagerIncidentMapping, EventManagerIncidentSpec, EventManagerInstance, EventManagerPayload, EventManagerProblemCommentSpec, EventManagerProblemMapping, EventManagerProblemSpec, EventManagerProblemSpecAction, EventManagerSnippet, EventManagerTest, EventManagerTestOverride, EventManagerTestPayload, EventManagerVersion, FeedbackItem, FileDownloadKey, IdentifiedItem, Job, JobClaim, JsonBlob, MacroParameterDefault, MacroSpec, MacroSpecExample, MacroSpecParameter, MagicSuiteVersionInfo, MerlinChatRequest, Metric, NamedItem, Notification, NotificationAttachment, NotificationRecipient, Person, Project, ProjectIssue, ProjectIssueComment, ProjectTimeEntry, QuartzEntry, ReportBatchJob, ReportJob, ReportJobConnectionSummary, ReportMacroResult, ReportMacroResultAggregation, ReportMacroTypeInfo, ReportSchedule, Role, RoleMembership, RolePermission, Setting, Subscription, Sync, SyncConnectedSystem, SyncConnectedSystemDataSet, SyncConnectedSystemDataSetConstant, SyncConnectedSystemDataSetMapping, SyncStateDataSet, SyncVersion, Tenant, TenantBranding, UserNotification, VariableDefault, Widget, WidgetItem, WidgetNode, Worker

### 4. `tenant` - Tenant Selection and Management
Manages tenant context for operations.

**Subcommands:**
- `select <identifier>` - Switch to a different tenant
- `current` - Show the currently active tenant

### 5. `file` - Manage Files and Folders in Magic Suite File System
Provides file system operations for Magic Suite.

**Subcommands:**
- `list` - List files and folders
- `upload` - Upload a local file to Magic Suite
- `download` - Download a file from Magic Suite
- `delete` - Delete a file or folder
- `create-folder` - Create a new folder
- `rename` - Rename/move a file or folder
- `copy` - Copy a file or folder
- `search` - Search for files

**Examples:**
```powershell
magicsuite file list /Library
magicsuite file upload report.pdf /Reports/monthly.pdf
magicsuite file download /Reports/monthly.pdf ./local.pdf
magicsuite file search 'budget'
```

## Key Features
1. **Multi-tenant Support** - Switch between different tenants
2. **Profile Management** - Use different environment profiles (production, alpha3, local, etc.)
3. **Flexible Output** - JSON or Table format with file output option
4. **Authentication** - Token-based authentication with credential management
5. **Comprehensive API Access** - CRUD operations on 119+ entity types
6. **File Management** - Full file system operations within Magic Suite
7. **Filtering & Selection** - Filter and select specific fields when querying entities

## Common Use Cases
- Querying and managing Magic Suite entities (Cases, Projects, Reports, etc.)
- Managing tenant configurations and switching between tenants
- Uploading/downloading files to/from Magic Suite
- Automating API operations via command-line scripts
- Managing authentication tokens and profiles for different environments
- Performing bulk operations on entities using scripts

## Bug Testing Context
When testing this CLI tool and writing Jira tickets for bugs:
- Note which command and subcommand was being used
- Include the full command with all options used
- Specify the profile/tenant context if relevant
- Include the output format being used (JSON vs Table)
- Capture the full error output
- Note the version number (4.1.278+0db90d0a24)
- Include any authentication/profile configuration issues
- Specify if the issue occurs with specific entity types

## JIRA Integration

### JIRA Tool Location
The JIRA integration tool is located at `.github\tools\JIRA.ps1`

### JIRA Credentials
- **Credentials stored in**: Windows Credential Manager (target: `PanoramicData_JIRA`) OR environment variables (JIRA_USERNAME, JIRA_PASSWORD)
- **JIRA URL**: https://jira.panoramicdata.com
- **Setup Instructions**: See SETUP-INSTRUCTIONS.md for configuring your own credentials

### Creating Bug Tickets
When creating JIRA bug tickets for MagicSuite CLI issues:

**Required Fields:**
- `ProjectKey`: 'MS'
- `IssueType`: 'Bug' or 'Task'
- `Summary`: Clear, concise title
- `Description`: Detailed bug report with sections for Summary, Environment, Steps to Reproduce, Actual Result, Expected Result, Impact
- `customfield_11200`: Must be set to `@("MagicSuite_R&D")` (Toggl Project - required field)

**Example JIRA Bug Creation:**
```powershell
# Direct REST API approach (recommended for reliability)
$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = "Brief issue description"
        description = "Detailed description with formatting"
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
    -Method POST -Headers $headers -Body $body
```

### PowerShell Execution Policy
The execution policy is set to **RemoteSigned** for CurrentUser scope, allowing local scripts to run without bypass:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Example Bug Reports Created
- **MS-22521**: MagicSuite CLI: Null Reference Exception when listing ReportBatchJobs
  - Command: `magicsuite api get reportbatchjobs`
  - Error: NullReferenceException when fetching ReportBatchJob entities
  - Reproducible across all output formats (JSON/Table) and with --verbose flag
