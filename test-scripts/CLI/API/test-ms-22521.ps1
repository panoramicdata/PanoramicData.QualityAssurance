# Test script for MS-22521 - MagicSuite CLI: Null Reference Exception when listing ReportBatchJobs

# Get credentials using the helper script (Windows Credential Manager)
$credentialScript = Join-Path $PSScriptRoot "..\..\..\..\.github\tools\Get-JiraCredentials.ps1"
if (-not (Test-Path $credentialScript)) {
    $credentialScript = Join-Path $PSScriptRoot "..\..\..\.github\tools\Get-JiraCredentials.ps1"
}
$credentials = & $credentialScript
if (-not $credentials -or -not $credentials.Username -or -not $credentials.Password) {
    Write-Error "Failed to retrieve JIRA credentials."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($credentials.Username):$($credentials.Password)"))
    "Content-Type" = "application/json"
}

$comment = @"
Testing completed on December 9, 2025.

h3. Test Results: PASSED

The null reference exception issue has been resolved in the latest version.

h3. Test Steps Performed:
# Configured MagicSuite CLI authentication for test environment
# Tested command: {{magicsuite --profile AmyTest2 api get reportbatchjobs}}
# Result: Successfully retrieved 100 ReportBatchJob entities without errors
# Tested with {{--verbose}} flag: Worked correctly, no null reference exception
# Tested with {{--format Json}}: Worked correctly (displays as table by default in terminal)
# Tested with {{--format Table}}: Worked correctly (default behavior)

h3. Environment:
* Test Date: December 9, 2025
* MagicSuite CLI Version: 4.1.*
* Profile: AmyTest2 (https://api.test2.magicsuite.net)
* Authentication: Successfully configured and tested
* Result: SUCCESS - No null reference exceptions encountered

h3. Sample Output:
Successfully retrieved ReportBatchJob entities with Id and Name fields displayed in table format. The command returned "Found 100 ReportBatchJob(s)" confirming proper data retrieval and formatting.

h3. Conclusion:
The issue reported in this ticket has been fixed. The ReportBatchJob entity can now be queried successfully via the CLI without null reference exceptions. All tested configurations (default, verbose, JSON format, Table format) work correctly.

*Status: Ready to close/resolve*
"@

$body = @{
    body = $comment
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Adding test results comment to MS-22521..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22521/comment" `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host "Successfully added comment to MS-22521" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/MS-22521" -ForegroundColor Cyan
}
catch {
    Write-Host "Failed to add comment: $_" -ForegroundColor Red
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $responseBody = $reader.ReadToEnd()
    Write-Host "Response Body: $responseBody" -ForegroundColor Red
    exit 1
}
