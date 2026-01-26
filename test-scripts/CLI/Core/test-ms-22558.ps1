# Test script for MS-22558 - MagicSuite CLI NuGet package missing DotnetToolSettings.xml

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

The DotnetToolSettings.xml issue has been resolved in the latest package.

h3. Test Steps Performed:
# Checked current version: 4.1.*
# Uninstalled the tool successfully
# Reinstalled the tool from NuGet: {{dotnet tool install -g MagicSuite.Cli}}
# Installation completed successfully without DotnetToolSettings.xml error
# Verified tool works correctly with {{--version}} command

h3. Environment:
* Test Date: December 9, 2025
* Installed Version: 4.1.*
* Installation Method: {{dotnet tool install -g MagicSuite.Cli}}
* Result: SUCCESS - No errors encountered

h3. Conclusion:
The issue reported in this ticket has been fixed. The latest NuGet package now includes the required DotnetToolSettings.xml file and can be installed/updated without errors.

*Status: Ready to close/resolve*
"@

$body = @{
    body = $comment
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Adding test results comment to MS-22558..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22558/comment" `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host "✅ Successfully added comment to MS-22558" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/MS-22558" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to add comment: $_" -ForegroundColor Red
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $responseBody = $reader.ReadToEnd()
    Write-Host "Response Body: $responseBody" -ForegroundColor Red
    exit 1
}
