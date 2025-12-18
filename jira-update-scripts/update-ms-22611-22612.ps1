# Script to update MS-22611 and create MS-22612 with comprehensive information
# Date: 2025-12-18

Write-Host "`n=== Updating JIRA Tickets MS-22611 and MS-22612 ===" -ForegroundColor Cyan

# Get credentials from environment
$JIRA_USERNAME = $env:JIRA_USERNAME
$JIRA_PASSWORD = $env:JIRA_PASSWORD

if (-not $JIRA_USERNAME -or -not $JIRA_PASSWORD) {
    Write-Error "JIRA credentials not found in environment variables."
    Write-Host "Please set JIRA_USERNAME and JIRA_PASSWORD environment variables." -ForegroundColor Yellow
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JIRA_USERNAME}:${JIRA_PASSWORD}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Update MS-22611 with comprehensive information
Write-Host "`n1. Updating MS-22611 with comprehensive information..." -ForegroundColor Yellow

$update22611 = @{
    fields = @{
        description = @'
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
3. Check the exit code with {{$LASTEXITCODE}}

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
* Makes CI/CD integration unreliable

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

h2. Additional Test Cases
The test script validates multiple scenarios:
* Negative value: {{--take -5}}
* Zero value: {{--take 0}}
* Large negative value: {{--take -999999}}

All validation errors should return non-zero exit codes for proper error detection.
'@
        labels = @("CLI", "exit-codes", "validation", "automation-blocker")
        priority = @{id = "2"}  # Critical
    }
} | ConvertTo-Json -Depth 10

try {
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22611" -Method PUT -Headers $headers -Body $update22611
    Write-Host "  ✓ Updated MS-22611 successfully" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/MS-22611" -ForegroundColor Cyan
}
catch {
    Write-Host "  ✗ Failed to update MS-22611: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details:" -ForegroundColor Yellow
        $errorObj | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Yellow
    }
}

# Create MS-22612 with comprehensive information
Write-Host "`n2. Creating MS-22612 with comprehensive information..." -ForegroundColor Yellow

$description22612 = @'
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
3. Check the exit code with {{$LASTEXITCODE}}
4. Verify the file was not created

h2. Expected vs Actual Behavior
*Expected:*
* Error message displayed: Yes
* Exit code: Non-zero (1 or 2)
* OR automatically create parent directories

*Actual:*
* Error message displayed: Yes - "Could not find a part of the path 'C:\NonExistentDir\file.txt'."
* Exit code: 0 (INCORRECT)
* File not created (expected)

h2. Impact
* *CRITICAL: Silent data loss risk* - users expect data saved but write fails
* Scripts cannot detect file I/O errors
* Automation pipelines continue after output failures
* Difficult to debug automated workflows
* Subsequent pipeline steps may expect file to exist and fail unexpectedly
* Users may believe data was saved successfully when it wasn't

h2. Test Evidence
{code:powershell}
PS> magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"
Error: Could not find a part of the path 'C:\NonExistentDir\file.txt'.

PS> $LASTEXITCODE
0

PS> Test-Path "C:\NonExistentDir\file.txt"
False
{code}

h2. Additional Test Cases
The test script ({{test-scripts/test-ms-22612.ps1}}) validates multiple scenarios:
# *Test 1:* Output to non-existent directory
{{magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"}}

# *Test 2:* Output to deeply nested non-existent path
{{magicsuite api get tenants --take 1 --output "C:\NonExist1\NonExist2\NonExist3\file.txt"}}

# *Test 3:* Output to path with invalid characters (Windows)
{{magicsuite api get tenants --take 1 --output "C:\InvalidPath<>|?\file.txt"}}

All file I/O errors should return non-zero exit codes for proper error detection.

h2. Related Issues
* MS-22608 - Parent issue: MagicSuite CLI returns exit code 0 on failure
* MS-22611 - Sibling issue: Negative --take parameter returns exit code 0

h2. Test Script
Test script available: {{test-scripts/test-ms-22612.ps1}}

h2. Recommended Fix
Either:
1. Return non-zero exit code on file write failures (preferred for error detection)
2. Automatically create parent directories before writing (like {{mkdir -p}} behavior)
'@

$bug22612 = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "MagicSuite CLI: --output to non-existent directory returns exit code 0 on file write error"
        description = $description22612
        priority = @{id = "2"}  # Critical
        labels = @("CLI", "exit-codes", "file-io", "data-loss-risk", "automation-blocker")
        customfield_11200 = @('MagicSuite_R&D')
    }
} | ConvertTo-Json -Depth 10

try {
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $bug22612
    Write-Host "  ✓ Created MS-22612: $($result.key)" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/$($result.key)" -ForegroundColor Cyan
    
    # Link to MS-22608
    Write-Host "  Linking to MS-22608..." -ForegroundColor Gray
    $link1 = @{
        type = @{name = "Relates"}
        inwardIssue = @{key = $result.key}
        outwardIssue = @{key = "MS-22608"}
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method POST -Headers $headers -Body $link1 | Out-Null
    Write-Host "  ✓ Linked to MS-22608" -ForegroundColor Green
    
    # Link to MS-22611
    Write-Host "  Linking to MS-22611..." -ForegroundColor Gray
    $link2 = @{
        type = @{name = "Relates"}
        inwardIssue = @{key = $result.key}
        outwardIssue = @{key = "MS-22611"}
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method POST -Headers $headers -Body $link2 | Out-Null
    Write-Host "  ✓ Linked to MS-22611" -ForegroundColor Green
    
    $key22612 = $result.key
}
catch {
    Write-Host "  ✗ Failed to create MS-22612: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details:" -ForegroundColor Yellow
        $errorObj | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Yellow
    }
    $key22612 = $null
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "MS-22611: Updated with comprehensive information" -ForegroundColor Green
Write-Host "  URL: https://jira.panoramicdata.com/browse/MS-22611" -ForegroundColor Cyan
if ($key22612) {
    Write-Host "MS-22612: Created successfully ($key22612)" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/$key22612" -ForegroundColor Cyan
} else {
    Write-Host "MS-22612: Failed to create" -ForegroundColor Red
}
Write-Host "`nBoth tickets now include:" -ForegroundColor White
Write-Host "  • Comprehensive environment information" -ForegroundColor Gray
Write-Host "  • Detailed reproduction steps" -ForegroundColor Gray
Write-Host "  • Expected vs actual behavior" -ForegroundColor Gray
Write-Host "  • Impact analysis (automation blockers, data loss risk)" -ForegroundColor Gray
Write-Host "  • Test evidence with code examples" -ForegroundColor Gray
Write-Host "  • Links to related issues" -ForegroundColor Gray
Write-Host "  • Test script references" -ForegroundColor Gray
Write-Host "  • Additional test scenarios" -ForegroundColor Gray
Write-Host "`n"
