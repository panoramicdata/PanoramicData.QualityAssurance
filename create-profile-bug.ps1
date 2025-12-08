# Create JIRA bug for profile list active indicator issue

# Get credentials from environment variables
$username = $env:JIRA_USERNAME
$password = $env:JIRA_PASSWORD

if (-not $username -or -not $password) {
    Write-Host "❌ JIRA credentials not found in environment variables." -ForegroundColor Red
    Write-Host "Please set JIRA_USERNAME and JIRA_PASSWORD environment variables." -ForegroundColor Yellow
    exit 1
}

$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

$headers = @{
    "Authorization" = "Basic $credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$description = @"
*Summary*
The 'magicsuite config profiles list' command displays a question mark in the Active column for the active profile, instead of showing a checkmark/tick to indicate it is the currently active profile.

*Environment*
- MagicSuite CLI Version: 3.28.258+b2ef011bc7
- Installation Path: C:\Users\amycb\.dotnet\tools\magicsuite.exe
- Date Tested: December 2, 2025

*Steps to Reproduce*
1. Run command: magicsuite auth status
2. Observe that the profile AmyTest2 is shown as the active profile
3. Run command: magicsuite config profiles list
4. Observe that the Active column shows a question mark instead of a checkmark for the AmyTest2 profile

*Actual Result*
The profiles list command shows a question mark in the Active column for AmyTest2 profile.

However, magicsuite auth status clearly shows:
Authentication Status for Profile: AmyTest2

*Expected Result*
The Active column should display a checkmark/tick for the AmyTest2 profile since it is clearly the active profile as confirmed by the auth status command. The question mark suggests uncertainty or that the active status is unknown, which is misleading.

*Impact*
This is a UI/UX bug that causes confusion for users trying to determine which profile is currently active. While the auth status command shows the correct active profile, the profiles list command gives ambiguous information with the question mark, making it unclear which profile is in use.

*Severity*
Low - The functionality works correctly, but the UI indicator is misleading and causes user confusion.
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = "MagicSuite CLI: Profile list shows question mark instead of tick for active profile"
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating JIRA bug ticket..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $body
    Write-Host "Success! Created issue: $($response.key)" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
    $response
}
catch {
    Write-Host "Error Response:" -ForegroundColor Red
    Write-Host $_.Exception.Response.StatusCode
    Write-Host $_.Exception.Response.StatusDescription
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
    Write-Host $responseBody
}
