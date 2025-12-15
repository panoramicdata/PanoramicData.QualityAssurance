# Copilot Instructions for Panoramic Data Quality Assurance Team

## Team Information

This workspace is maintained by the **Panoramic Data Quality Assurance team**.

### Quality Assurance Team
- **Claire Campbell** - JIRA: `claire.campbell` - QA focus with testing assignments
- **Sam Walters** - JIRA: `sam.walters` - Handles testing activities, often assigned issues in "In Test" and "Ready for Test" status

### Magic Suite Project Team

The **Magic Suite project** is developed by the following team members:

**Main Developers:**
- **Roland Banks** - JIRA: `roland.banks`
- **John Odlin** - JIRA: `john.odlin`

**Additional Developers:**
- **David Bond** - JIRA: `david.bond`
- **Daniel Abbott** - JIRA: `daniel.abbott`

## JIRA Analysis Results

Based on analysis of the JIRA system (https://jira.panoramicdata.com), the following insights have been discovered:

### Project Structure
- **Main Project**: MS (Magic Suite) - Contains 4200+ issues
- **Team Focus**: All team members primarily work on Magic Suite project tickets
- **Workflow States**: Ready for Progress → In Progress → Ready for Test → In Test

### Team Role Analysis
**Quality Assurance Team:**
- **Sam Walters** (`sam.walters`) - Handles testing activities, often assigned issues in "In Test" and "Ready for Test" status
- **Claire Campbell** (`claire.campbell`) - QA focus with testing assignments

**Main Developers:**
- **Roland Banks** (`roland.banks`) - Senior developer working on API and backend components, handles critical/blocker issues
- **John Odlin** (`john.odlin`) - UI/Frontend specialist, works on DataMagic and AlertMagic components

**Additional Developers:**
- **David Bond** (`david.bond`) - Active contributor (current user running this analysis)
- **Daniel Abbott** - Username format may vary (verification needed)

### Key Application Components
- **DataMagic** - Database and data visualization components
- **AlertMagic** - Alerting and notification system  
- **Files UI** - File management interface (SharePoint integration)
- **Estate Tree** - Navigation and hierarchy management

## Project Overview

This repository contains quality assurance tools, test plans, and automation scripts for Panoramic Data's testing processes, with a focus on the Magic Suite project and related systems. The team manages testing workflows across multiple systems including JIRA for issue tracking and Elastic for log analysis and monitoring.

## Available Tools

The `.github/tools/` directory contains PowerShell scripts for system integration:

### JIRA Integration (`tools/JIRA.ps1`)
- Connects to JIRA instance using environment variables
- Required environment variables:
  - `JIRA_USERNAME` - Your JIRA username
  - `JIRA_PASSWORD` - Your JIRA password/API token
- JIRA URL: `https://jira.panoramicdata.com`

### Elastic Integration (`tools/Elastic.ps1`)
- Connects to Elastic cluster using environment variables
- Required environment variables:
  - `ELASTIC_USERNAME` - Your Elastic username
  - `ELASTIC_PASSWORD` - Your Elastic password
- Elastic URL: `https://pdl-elastic-prod.panoramicdata.com`

### Playwright MCP Integration (`playwright/`)
- **Purpose**: AI-assisted browser automation for UI testing
- **Documentation**: See `playwright/README.md` for full setup instructions
- **Configuration**: Add to `.vscode/mcp.json` to enable Playwright MCP tools
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
        "args": ["@playwright/mcp@latest", "--browser", "chrome", "--caps", "vision"]
      }
    }
  }
  ```
- **Task-Specific Instructions**: See `.github/playwright-instructions.md` for Magic Suite URL patterns, environments, and test conventions

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

6. **JIRA.ps1 Script Enhancement Guidelines**:
   - **Current capabilities**: get, search, create, update, comment, transition, team actions
   - **Enhanced ticket access**: getfull, detailed, comments, history actions for comprehensive ticket information
   - **Ticket data includes**: All comments, state transitions, change history, and formatted summaries
   - **Add new functions** when you need capabilities not currently available
   - **Follow the existing pattern**: Add a new function, then add a new case in the switch statement
   - **Update the help text** in the default action when adding new functionality
   - **Test new functions** before using them in production workflows
   - **Document new parameters** and provide usage examples
   - **Common extensions needed**: bulk operations, advanced filtering, reporting functions, user management

7. **When working with Elastic**:
   - Be cautious with query operations on production data
   - Use appropriate time ranges to avoid performance impact
   - Verify index patterns before executing searches
   - Document any custom queries for future reference

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
