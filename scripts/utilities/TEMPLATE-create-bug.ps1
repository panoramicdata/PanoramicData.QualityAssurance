# Template for Creating JIRA Bug Reports

# Get credentials using the helper script (Windows Credential Manager)
$credentialScript = Join-Path $PSScriptRoot "..\..\..\.github\tools\Get-JiraCredentials.ps1"
if (-not (Test-Path $credentialScript)) {
    $credentialScript = Join-Path $PSScriptRoot "..\..\.github\tools\Get-JiraCredentials.ps1"
}
$credentials = & $credentialScript
if (-not $credentials -or -not $credentials.Username -or -not $credentials.Password) {
    Write-Host "Failed to retrieve JIRA credentials." -ForegroundColor Red
    exit 1
}

$username = $credentials.Username
$password = $credentials.Password

$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

$headers = @{
    'Authorization' = "Basic $base64Auth"
    'Content-Type' = 'application/json'
}

# CUSTOMIZE THIS SECTION FOR YOUR BUG
$summary = "Brief description of the bug"
$description = @"
*Summary*
Brief description of the issue.

*Environment*
- MagicSuite CLI Version: $(magicsuite --version)
- Installation Path: $(where.exe magicsuite)
- PowerShell Version: $($PSVersionTable.PSVersion)
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

*Steps to Reproduce*
1. Step one
2. Step two
3. Step three

*Actual Result*
What actually happened

*Expected Result*
What should have happened

*Additional Information*
{code}
Error output or relevant details here
{code}

*Impact*
How this affects users/functionality
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = $summary
        description = $description
        customfield_11200 = @("MagicSuite_R&D")  # Required: Toggl Project field
    }
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Creating JIRA bug ticket..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host "✅ Successfully created bug: $($response.key)" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to create bug: $_" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Yellow
}
