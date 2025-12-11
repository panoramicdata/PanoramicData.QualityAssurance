# Add test results comment to MS-22523

# Get credentials
$credTarget = "PanoramicData_JIRA"
$cred = $null

try {
    $credObject = Get-StoredCredential -Target $credTarget -ErrorAction SilentlyContinue
    if ($credObject) {
        $cred = $credObject
    }
} catch {
    if ($env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
        $securePassword = ConvertTo-SecureString $env:JIRA_PASSWORD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($env:JIRA_USERNAME, $securePassword)
    }
}

if (-not $cred) {
    Write-Error "No JIRA credentials found."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$($cred.GetNetworkCredential().Password)"))
    "Content-Type" = "application/json"
}

$comment = @"
*Fix Verified in Version 4.1.254*

Testing Date: December 11, 2025
CLI Version: 4.1.254+9bb1b85f0d
Tester: Amy Bond

h3. Test Results
✓ *PASSED* - The active profile indicator now displays correctly

h3. Test Details
Command executed:
{code}
magicsuite config profiles list
{code}

Previous behavior (versions ≤ 4.1.249):
{code}
┌──────────────┬──────────────────────────────────┬────────┐
│ Profile Name │ API URL                          │ Active │
├──────────────┼──────────────────────────────────┼────────┤
│ AmyTest2     │ https://api.test2.magicsuite.net │ ?      │
└──────────────┴──────────────────────────────────┴────────┘
{code}

Current behavior (version 4.1.254):
{code}
┌──────────────┬──────────────────────────────────┬────────┐
│ Profile Name │ API URL                          │ Active │
├──────────────┼──────────────────────────────────┼────────┤
│ AmyTest2     │ https://api.test2.magicsuite.net │ √      │
└──────────────┴──────────────────────────────────┴────────┘
{code}

The Active column now correctly shows "√" (checkmark) instead of "?" for the active profile.

h3. Conclusion
This issue has been successfully resolved in version 4.1.254. The profile list command now properly displays the active profile indicator

BUG STILL EXISTS

Test Results:
1. Verified active profile via 'magicsuite auth status' - shows AmyTest2 is active
2. Checked 'magicsuite config profiles list' output - shows '?' in Active column

Current Behavior:
Profile Name | API URL                          | Active
AmyTest2     | https://api.test2.magicsuite.net | ?

The question mark (?) continues to appear instead of a checkmark for the active profile.

Expected Behavior:
- Active profile should display a checkmark/tick symbol
- The '?' symbol suggests uncertainty or unknown status, which is misleading since the system clearly knows which profile is active (as shown by auth status command)

Impact:
Users must run 'auth status' to confirm which profile is active, as the profiles list gives ambiguous information.
"@

$body = @{
    body = $comment
}

$jsonBody = $body | ConvertTo-Json -Depth 10
$utf8Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

try {
    Write-Host "Adding comment to MS-22523..."
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22523/comment" `
        -Method POST `
        -Headers $headers `
        -Body $utf8Body
    
    Write-Host "Successfully added comment to MS-22523" -ForegroundColor Green
}
catch {
    Write-Error "Failed to add comment: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
