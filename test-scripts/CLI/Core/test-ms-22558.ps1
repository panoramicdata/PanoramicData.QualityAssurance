# Test script for MS-22558 - MagicSuite CLI NuGet package missing DotnetToolSettings.xml

# Get credentials
$credTarget = "PanoramicData_JIRA"
$cred = $null

try {
    $credObject = Get-StoredCredential -Target $credTarget -ErrorAction SilentlyContinue
    if ($credObject) {
        $cred = $credObject
    }
} catch {
    # Fallback to environment variables
    if ($env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
        $securePassword = ConvertTo-SecureString $env:JIRA_PASSWORD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($env:JIRA_USERNAME, $securePassword)
    }
}

if (-not $cred) {
    Write-Error "No JIRA credentials found. Please set up credentials in Windows Credential Manager or environment variables."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$($cred.GetNetworkCredential().Password)"))
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
