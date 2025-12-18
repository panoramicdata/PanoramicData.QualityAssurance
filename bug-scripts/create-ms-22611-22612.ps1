# Script to create JIRA tickets MS-22611 and MS-22612
# These are CLI exit code bugs discovered during testing on 2025-12-18

Write-Host "`n=== Creating JIRA Tickets for CLI Exit Code Bugs ===" -ForegroundColor Cyan

# Get credentials
$cred = Get-StoredCredential -Target "PanoramicData_JIRA"
if (-not $cred) {
    Write-Error "No JIRA credentials found. Run setup first."
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$($cred.GetNetworkCredential().Password)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# MS-22611: Negative --take parameter returns exit code 0
Write-Host "`n1. Creating MS-22611..." -ForegroundColor Yellow

$bug1 = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "MagicSuite CLI: Negative --take parameter returns exit code 0 on validation error"
        description = @"
h2. Summary
When the MagicSuite CLI encounters a validation error for a negative --take parameter value, it displays an appropriate error message but incorrectly returns exit code 0, making validation errors undetectable by scripts and automation workflows.

h2. Environment
* *CLI Version:* 4.1.323+b1d2df9293
* *Test Environment:* test.magicsuite.net
* *Test Date:* 2025-12-18
* *Operating System:* Windows
* *PowerShell Version:* 5.1

h2. Steps to Reproduce
1. Run the following command:
{{magicsuite api get tenants --take -5}}
2. Observe the error message displayed
3. Check the exit code

h2. Expected vs Actual Behavior
*Expected:*
* Error message displayed: Yes
* Exit code: Non-zero (1 or 2)

*Actual:*
* Error message displayed: Yes - "The 'take' parameter must be greater than or equal to zero. (Parameter 'take') Actual value was -5."
* Exit code: 0 (INCORRECT)

h2. Impact
* Scripts cannot detect validation errors
* Automation pipelines treat validation errors as success
* Inconsistent with CLI best practices
* May cause cascading failures in automated workflows

h2. Test Evidence
{code:powershell}
PS> magicsuite api get tenants --take -5
Error: The 'take' parameter must be greater than or equal to zero.
Actual value was -5.

PS> $LASTEXITCODE
0
{code}

h2. Related Issues
* MS-22608 - Parent issue: MagicSuite CLI returns exit code 0 on failure
* MS-22612 - Sibling issue: --output directory error returns exit code 0

h2. Test Script
Test script available: {{test-scripts/test-ms-22611.ps1}}
"@
        priority = @{id = "2"}  # Critical
        labels = @("CLI", "exit-codes", "validation", "automation-blocker")
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

try {
    $result1 = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $bug1
    Write-Host "  ✓ Created: $($result1.key)" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/$($result1.key)" -ForegroundColor Cyan
    
    # Link to MS-22608
    $link1 = @{type=@{name="Relates"};inwardIssue=@{key=$result1.key};outwardIssue=@{key="MS-22608"}} | ConvertTo-Json
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method POST -Headers $headers -Body $link1 | Out-Null
    Write-Host "  ✓ Linked to MS-22608" -ForegroundColor Green
    
    $key1 = $result1.key
}
catch {
    Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details: $($errorObj.errors | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    }
    $key1 = $null
}

# MS-22612: --output to non-existent directory returns exit code 0
Write-Host "`n2. Creating MS-22612..." -ForegroundColor Yellow

$bug2 = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "MagicSuite CLI: --output to non-existent directory returns exit code 0 on file write error"
        description = @"
h2. Summary
When the MagicSuite CLI encounters a file I/O error (attempting to write output to a non-existent directory path), it displays an error message but incorrectly returns exit code 0, making file write failures undetectable and creating a risk of silent data loss.

h2. Environment
* *CLI Version:* 4.1.323+b1d2df9293
* *Test Environment:* test.magicsuite.net
* *Test Date:* 2025-12-18
* *Operating System:* Windows
* *PowerShell Version:* 5.1

h2. Steps to Reproduce
1. Run the following command with a non-existent directory:
{{magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"}}
2. Observe the error message displayed
3. Check the exit code

h2. Expected vs Actual Behavior
*Expected:*
* Error message displayed: Yes
* Exit code: Non-zero (1 or 2)
* OR automatically create parent directories

*Actual:*
* Error message displayed: Yes - "Could not find a part of the path 'C:\NonExistentDir\file.txt'."
* Exit code: 0 (INCORRECT)

h2. Impact
* Silent data loss risk - users expect data saved but write fails
* Scripts cannot detect file I/O errors
* Automation pipelines continue after output failures
* Difficult to debug automated workflows
* Subsequent steps may expect file to exist

h2. Test Evidence
{code:powershell}
PS> magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"
Error: Could not find a part of the path 'C:\NonExistentDir\file.txt'.

PS> $LASTEXITCODE
0

PS> Test-Path "C:\NonExistentDir\file.txt"
False
{code}

h2. Related Issues
* MS-22608 - Parent issue: MagicSuite CLI returns exit code 0 on failure
* MS-22611 - Sibling issue: Negative --take parameter returns exit code 0

h2. Test Script
Test script available: {{test-scripts/test-ms-22612.ps1}}
"@
        priority = @{id = "2"}  # Critical
        labels = @("CLI", "exit-codes", "file-io", "data-loss-risk", "automation-blocker")
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

try {
    $result2 = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $bug2
    Write-Host "  ✓ Created: $($result2.key)" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/$($result2.key)" -ForegroundColor Cyan
    
    # Link to MS-22608
    $link1 = @{type=@{name="Relates"};inwardIssue=@{key=$result2.key};outwardIssue=@{key="MS-22608"}} | ConvertTo-Json
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method POST -Headers $headers -Body $link1 | Out-Null
    Write-Host "  ✓ Linked to MS-22608" -ForegroundColor Green
    
    # Link to MS-22611 (if it was created)
    if ($key1) {
        $link2 = @{type=@{name="Relates"};inwardIssue=@{key=$result2.key};outwardIssue=@{key=$key1}} | ConvertTo-Json
        Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method POST -Headers $headers -Body $link2 | Out-Null
        Write-Host "  ✓ Linked to $key1" -ForegroundColor Green
    }
    
    $key2 = $result2.key
}
catch {
    Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details: $($errorObj.errors | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    }
    $key2 = $null
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($key1) {
    Write-Host "✓ MS-22611 created: https://jira.panoramicdata.com/browse/$key1" -ForegroundColor Green
} else {
    Write-Host "✗ MS-22611 creation failed" -ForegroundColor Red
}

if ($key2) {
    Write-Host "✓ MS-22612 created: https://jira.panoramicdata.com/browse/$key2" -ForegroundColor Green
} else {
    Write-Host "✗ MS-22612 creation failed" -ForegroundColor Red
}

Write-Host "`nBoth tickets linked to MS-22608 (parent issue)" -ForegroundColor Gray
Write-Host "Test scripts available in test-scripts/ directory" -ForegroundColor Gray
