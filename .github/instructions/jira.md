# JIRA Integration Instructions

## Tool Location
`.github/tools/JIRA.ps1`

## Critical Rules
- **ALWAYS use JIRA.ps1** for interactions - never direct REST API (except complex bug creation)
- **Extend the script** if functionality is missing rather than bypassing it
- **Update tickets proactively** with progress comments throughout work
- **Include environment + version** in all test results

## Authentication
The script uses Windows Credential Manager as the primary credential store. Environment variables are deprecated and will be automatically migrated.

**Credential Priority:**
1. **Command line parameters** (`-Username` and `-Password`) - for CI/automation only
2. **Windows Credential Manager** (`PanoramicData.JIRA`) - preferred persistent storage
3. **Environment variables** (legacy) - auto-migrated to Credential Manager, then removed
4. **Interactive prompt** - stores new credentials in Windows Credential Manager

- **JIRA URL**: https://jira.panoramicdata.com (or set `JIRA_BASEURL` environment variable)
- **Project Key**: MS (Magic Suite)

### Managing Credentials
```powershell
# View Windows Credential Manager stored credential
cmdkey /list:PanoramicData.JIRA

# Delete stored credential (to re-enter)
cmdkey /delete:PanoramicData.JIRA

# Manually add credential
cmdkey /generic:PanoramicData.JIRA /user:your.username /pass:your.password
```

### Legacy Environment Variables (Deprecated)
If environment variables are detected, they will be automatically migrated to Windows Credential Manager and removed:
```powershell
# Check if legacy env vars exist (should be empty)
[Environment]::GetEnvironmentVariable('JIRA_USERNAME', 'User')
[Environment]::GetEnvironmentVariable('JIRA_PASSWORD', 'User')
```

## Available Actions

| Action | Description |
|--------|-------------|
| `query` | Query tickets or users (default) |
| `create` | Create new tickets |
| `comment` | Add comment to a ticket |
| `update-comment` | Update existing comment |
| `delete-comment` | Delete a comment |
| `transition` | Transition ticket to new status |
| `transitions` | List available transitions for a ticket |
| `set-fixversion` | Set fix version on a ticket |
| `set-sprint` | Move ticket to a sprint |
| `update-ticket` | Update ticket fields |
| `link-issues` | Link two issues together |
| `attach-file` | Attach file to a ticket |
| `download-attachment` | Download attachment from a ticket |
| `get-history` | Get change history for a ticket |
| `list-components` | List available components for a project |

## Common Actions

### Get Ticket Information
```powershell
# Query single ticket by JQL
.\.github\tools\JIRA.ps1 -Action query -Jql 'key = MS-12345'

# Query with all fields
.\.github\tools\JIRA.ps1 -Action query -Jql 'key = MS-12345' -Fields all

# Query with comments included
.\.github\tools\JIRA.ps1 -Action query -Jql 'key = MS-12345' -IncludeComments
```

### Search Tickets
```powershell
# JQL search
.\.github\tools\JIRA.ps1 -Action query -Jql 'project = MS AND status = "Ready for Test"' -MaxResults 50

# Search with specific fields
.\.github\tools\JIRA.ps1 -Action query -Jql 'assignee = currentUser()' -Fields custom -CustomFields 'key,summary,status'
```

### Add Comments
```powershell
.\.github\tools\JIRA.ps1 -Action comment -IssueKey MS-12345 -Comment "Progress update..."

# Multi-line comment with Jira markup
.\.github\tools\JIRA.ps1 -Action comment -IssueKey MS-12345 -Comment @"
h3. Update

Testing complete.
- All tests passed
- No regressions
"@
```

### Transition Tickets
```powershell
# List available transitions first
.\.github\tools\JIRA.ps1 -Action transitions -IssueKey MS-12345

# Transition to new status
.\.github\tools\JIRA.ps1 -Action transition -IssueKey MS-12345 -TransitionName "In Progress"
```

**Common Transitions**:
- Ready for Progress → In Progress
- In Progress → Ready for Test
- Ready for Test → In Test
- In Test → Closed/Resolved

## Creating Bug Tickets

### Using REST API (for complex tickets)
Required when ticket needs labels, priority, custom fields.

```powershell
# Build authentication
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Create description (use variable, not here-string in hashtable)
$description = 'h2. Summary
Bug description

h2. Environment
* CLI Version: 4.1.546
* Test Date: 2026-01-13'

# Create issue
$issue = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "Brief description"
        description = $description
        priority = @{id = "2"}  # 2=Critical, 3=High, 4=Medium
        labels = @("CLI", "exit-codes")
        customfield_11200 = @('MagicSuite_R&D')  # Required for MS project!
    }
} | ConvertTo-Json -Depth 10

# Submit
$result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
    -Method POST -Headers $headers -Body $issue

Write-Host "Created: $($result.key)"
```

## Workflow Tracking

### Starting Work
1. Get ticket details: `.\.github\tools\JIRA.ps1 -Action query -Jql 'key = MS-12345' -IncludeComments`
2. Transition to "In Progress"
3. Add comment: "Starting work on MS-12345. Creating test plan..."
4. Confirm test environment

### During Work
Post progress comments at milestones:
- Test plan created
- Logs collected
- Analysis complete
- Blockers encountered

**Example Comment**:
```
Progress Update: Created test plan with 6 test cases.
Collected 1.25MB of logs from Elastic for analysis.
Environment: test2.magicsuite.net
Version: v4.1.546
Next: Running regression tests
```

### Completing Work
1. Final comment with findings and artifacts
2. Transition to "Ready for Test" or "In Test"
3. Include: Environment, version, test date, results

**Example Completion Comment**:
```
Testing Complete
Environment: test2.magicsuite.net
Application: DataMagic
Version: v4.1.546
Test Date: 2026-01-13 14:30:00
Browser: Firefox 144.0.2

Results:
✓ All 6 test cases passed
✓ No regressions found
✓ Performance within acceptable limits

Artifacts:
- Test Plan: test-plans/MS-12345.md
- Screenshots: playwright/screenshots/
- Test Results: test-results/MS-12345-results.md
```

## Common Pitfalls

### Bug Creation Issues
- ❌ **Ampersands**: Use single quotes `@('MagicSuite_R&D')` not double quotes
- ❌ **Here-strings in hashtables**: Use variables instead
- ❌ **Missing customfield_11200**: Required for MS project tickets
- ❌ **Wrong priority format**: Use `@{id = "2"}` not string `"Critical"`
- ❌ **Labels not array**: Must be `@("label1", "label2")` not string

### Priority IDs
| Priority | ID |
|----------|---|
| Critical | 2 |
| High | 3 |
| Medium | 4 |
| Low | 5 |

## Team Members

### QA Team
- **Amy Bond** (`amy.bond`)
- **Claire Campbell** (`claire.campbell`)
- **Sam Walters** (`sam.walters`)

### Developers
- **Roland Banks** (`roland.banks`) - API/backend, critical issues
- **John Odlin** (`john.odlin`) - UI/Frontend, DataMagic
- **David Bond** (`david.bond`)
- **Daniel Abbott**

## Extending JIRA.ps1

When adding new functionality:
1. Add new function following existing patterns
2. Add new case in switch statement
3. Update help text in default action
4. Test thoroughly before using
5. Document parameters and examples
