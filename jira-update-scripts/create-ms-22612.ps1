# Simple script to create MS-22612 JIRA ticket
# Date: 2025-12-18

Write-Host "Creating JIRA ticket MS-22612..." -ForegroundColor Cyan

# Get credentials
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

# Create the description text
$desc = 'h2. Summary
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
* Error message displayed: Yes - "Could not find a part of the path"
* Exit code: 0 (INCORRECT)
* File not created (expected)

h2. Impact
* *CRITICAL: Silent data loss risk* - users expect data saved but write fails
* Scripts cannot detect file I/O errors
* Automation pipelines continue after output failures
* Difficult to debug automated workflows
* Subsequent pipeline steps may expect file to exist and fail unexpectedly
* Users may believe data was saved successfully when it was not

h2. Test Evidence
{code:powershell}
PS> magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"
Error: Could not find a part of the path

PS> $LASTEXITCODE
0

PS> Test-Path "C:\NonExistentDir\file.txt"
False
{code}

h2. Additional Test Cases
The test script ({{test-scripts/test-ms-22612.ps1}}) validates multiple scenarios:
# *Test 1:* Output to non-existent directory
# *Test 2:* Output to deeply nested non-existent path
# *Test 3:* Output to path with invalid characters (Windows)

All file I/O errors should return non-zero exit codes for proper error detection.

h2. Related Issues
* MS-22608 - Parent issue: MagicSuite CLI returns exit code 0 on failure
* MS-22611 - Sibling issue: Negative --take parameter returns exit code 0

h2. Test Script
Test script available: {{test-scripts/test-ms-22612.ps1}}

h2. Recommended Fix
Either:
1. Return non-zero exit code on file write failures (preferred for error detection)
2. Automatically create parent directories before writing (like mkdir -p behavior)'

# Create issue payload
$issue = @{
    fields = @{
        project = @{
            key = "MS"
        }
        issuetype = @{
            name = "Bug"
        }
        summary = "MagicSuite CLI: --output to non-existent directory returns exit code 0 on file write error"
        description = $desc
        priority = @{
            id = "2"
        }
        labels = @("CLI", "exit-codes", "file-io", "data-loss-risk", "automation-blocker")
        customfield_11200 = @('MagicSuite_R&D')
    }
}

$body = $issue | ConvertTo-Json -Depth 10

try {
    Write-Host "Sending create request..." -ForegroundColor Gray
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST -Headers $headers -Body $body
    
    Write-Host "✓ Created: $($result.key)" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/$($result.key)" -ForegroundColor Cyan
    
    $newKey = $result.key
    
    # Link to MS-22608
    Write-Host "Linking to MS-22608..." -ForegroundColor Gray
    $link1 = @{
        type = @{name = "Relates"}
        inwardIssue = @{key = $newKey}
        outwardIssue = @{key = "MS-22608"}
    } | ConvertTo-Json -Depth 5
    
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" `
        -Method POST -Headers $headers -Body $link1 | Out-Null
    Write-Host "✓ Linked to MS-22608" -ForegroundColor Green
    
    # Link to MS-22611
    Write-Host "Linking to MS-22611..." -ForegroundColor Gray
    $link2 = @{
        type = @{name = "Relates"}
        inwardIssue = @{key = $newKey}
        outwardIssue = @{key = "MS-22611"}
    } | ConvertTo-Json -Depth 5
    
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" `
        -Method POST -Headers $headers -Body $link2 | Out-Null
    Write-Host "✓ Linked to MS-22611" -ForegroundColor Green
    
    Write-Host "`n✓ MS-22612 created successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Response:" -ForegroundColor Yellow
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5 | Write-Host
    }
    exit 1
}
