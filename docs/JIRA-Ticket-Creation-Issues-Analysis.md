# JIRA Ticket Creation - Issues Analysis and Resolution

**Date:** December 18, 2025  
**Context:** Creating MS-22611 and MS-22612 tickets with comprehensive information

## What Went Wrong

### Issue #1: Using Get-StoredCredential (Not Available)

**Problem:**
```powershell
$cred = Get-StoredCredential -Target "PanoramicData_JIRA"
```

**Error:**
```
Get-StoredCredential : The term 'Get-StoredCredential' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

**Why:** The `Get-StoredCredential` cmdlet is from the `CredentialManager` module, which may not be installed on all systems. It's not a built-in PowerShell cmdlet.

**Solution:** Use environment variables instead:
```powershell
$JIRA_USERNAME = $env:JIRA_USERNAME
$JIRA_PASSWORD = $env:JIRA_PASSWORD
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JIRA_USERNAME}:${JIRA_PASSWORD}"))
```

### Issue #2: Here-String Syntax Inside Hashtables

**Problem:**
```powershell
$bug = @{
    fields = @{
        description = @"
h2. Summary
Some text with "quotes" and special characters
"@
    }
}
```

**Error:**
```
The string is missing the terminator: ".
Unexpected token...
```

**Why:** PowerShell's here-string syntax (`@"..."@`) can cause parsing errors when used inside hashtables, especially when the content contains special characters, quotes, or certain keywords (like numbered lists).

**Solution:** Assign the description to a variable first:
```powershell
$description = 'h2. Summary
Some text here'

$bug = @{
    fields = @{
        description = $description
    }
}
```

### Issue #3: Ampersand Character in Strings

**Problem:**
```powershell
customfield_11200 = @("MagicSuite_R&D")
```

**Error:**
```
The ampersand (&) character is not allowed. The & operator is reserved for future use
```

**Why:** PowerShell interprets `&` as the call operator. Inside double quotes, it needs special handling.

**Solution:** Use single quotes instead:
```powershell
customfield_11200 = @('MagicSuite_R&D')
```

### Issue #4: JIRA.ps1 Create Action Limitations

**Problem:** The JIRA.ps1 script's `Create` action only supports basic fields:
```powershell
function New-JiraIssue {
    param(
        [string]$ProjectKey,
        [string]$IssueType,
        [string]$Summary,
        [string]$Description,
        [string]$Assignee = $null
    )
    # Missing: labels, priority, customfield_11200, etc.
}
```

**Why:** The original implementation was simplified and doesn't support all JIRA fields needed for comprehensive bug tickets.

**Solution Options:**
1. **Best:** Extend JIRA.ps1 with a `New-JiraIssueFull` function
2. **Temporary:** Use direct REST API calls with proper environment variable handling

## The Fix That Worked

### Working Script Pattern
```powershell
# 1. Get credentials from environment (NOT Get-StoredCredential)
$JIRA_USERNAME = $env:JIRA_USERNAME
$JIRA_PASSWORD = $env:JIRA_PASSWORD

if (-not $JIRA_USERNAME -or -not $JIRA_PASSWORD) {
    Write-Error "JIRA credentials not found. Set JIRA_USERNAME and JIRA_PASSWORD environment variables."
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JIRA_USERNAME}:${JIRA_PASSWORD}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# 2. Store description in a variable FIRST (avoid here-strings in hashtables)
$description = 'h2. Summary
When the MagicSuite CLI encounters an error...

h2. Environment
* *CLI Version:* 4.1.323
* *Test Date:* 2025-12-18'

# 3. Create issue with all required fields
$issue = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "Brief description"
        description = $description  # Use variable, not here-string
        priority = @{id = "2"}  # Critical - use object with id property
        labels = @("CLI", "exit-codes", "automation-blocker")  # Array of strings
        customfield_11200 = @('MagicSuite_R&D')  # Single quotes for ampersand!
    }
} | ConvertTo-Json -Depth 10

# 4. Make the API call
try {
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST -Headers $headers -Body $issue
    Write-Host "✓ Created: $($result.key)"
}
catch {
    Write-Host "✗ Failed: $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) {
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5
    }
}
```

## Key Lessons Learned

### 1. Credential Management
- ❌ **Don't use:** `Get-StoredCredential` (requires additional module)
- ✅ **Do use:** Environment variables (`$env:JIRA_USERNAME`, `$env:JIRA_PASSWORD`)

### 2. String Handling in Hashtables
- ❌ **Don't use:** Here-strings (`@"..."@`) inside hashtables
- ✅ **Do use:** Assign to variable first, then reference

### 3. Special Characters
- ❌ **Don't use:** Double quotes around strings with ampersands
- ✅ **Do use:** Single quotes: `@('MagicSuite_R&D')`

### 4. JIRA Field Requirements
- **Priority:** Must be object with `id` property: `@{id = "2"}`
- **Labels:** Must be array: `@("label1", "label2")`
- **Custom Fields:** Use correct field name: `customfield_11200`
- **Required Fields:** Always include `customfield_11200` for MS project

### 5. When to Extend JIRA.ps1 vs Direct API
- **Use JIRA.ps1:** For basic operations (get, search, comment, transition)
- **Extend JIRA.ps1:** When you need functionality repeatedly
- **Direct API (temporary):** When you need advanced fields immediately and JIRA.ps1 doesn't support them

## Success Outcome

Both tickets were successfully created/updated:
- **MS-22611:** Updated with comprehensive information
- **MS-22612:** Created with comprehensive information including:
  - ✓ Detailed environment info
  - ✓ Reproduction steps
  - ✓ Impact analysis
  - ✓ Test evidence
  - ✓ Critical priority
  - ✓ Proper labels
  - ✓ Required custom field
  - ✓ Links to related issues

## Updated Copilot Instructions

The `.github/copilot-instructions.md` file has been updated with:
1. Comprehensive JIRA.ps1 documentation
2. Common pitfalls when creating tickets
3. Working examples showing proper syntax
4. Clear guidance on when to use JIRA.ps1 vs direct API calls
5. Emphasis on ALWAYS using the JIRA tool as first choice

## Future Improvements

To prevent these issues in the future:
1. **Extend JIRA.ps1** with `New-JiraIssueFull` function supporting:
   - Labels
   - Priority
   - Custom fields (customfield_11200, etc.)
   - Issue links
   - All standard JIRA fields

2. **Add validation** to catch common errors:
   - Check for environment variables before proceeding
   - Validate required fields for MS project tickets
   - Provide better error messages

3. **Create templates** for common ticket types:
   - Bug ticket template
   - Feature request template
   - Task ticket template
