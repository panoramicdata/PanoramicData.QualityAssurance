# Test JIRA issue creation with verbose error handling

# Get credentials using the helper script (Windows Credential Manager)
$credentialScript = Join-Path $PSScriptRoot "..\..\..\.github\tools\Get-JiraCredentials.ps1"
if (-not (Test-Path $credentialScript)) {
    $credentialScript = Join-Path $PSScriptRoot "..\..\.github\tools\Get-JiraCredentials.ps1"
}
$credentials = & $credentialScript
if (-not $credentials -or -not $credentials.Username -or -not $credentials.Password) {
    Write-Host "❌ Failed to retrieve JIRA credentials." -ForegroundColor Red
    exit 1
}

$username = $credentials.Username
$password = $credentials.Password

$authHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

$headers = @{
    "Authorization" = "Basic $authHeader"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = "MagicSuite CLI: Null Reference Exception when listing ReportBatchJobs"
        description = @"
*Summary*
The 'magicsuite api get reportbatchjobs' command throws a null reference exception and fails to retrieve any data.

*Environment*
- MagicSuite CLI Version: 3.28.258+b2ef011bc7
- Installation Path: C:\Users\amycb\.dotnet\tools\magicsuite.exe
- Date Tested: December 2, 2025

*Steps to Reproduce*
1. Run command: magicsuite api get reportbatchjobs
2. Observe the error

*Actual Result*
{code}
Fetching ReportBatchJob...
Error: Exception has been thrown by the target of an invocation.
Object reference not set to an instance of an object.
{code}

*Expected Result*
The command should return a list of ReportBatchJob entities in table format, or an empty result if no entities exist.

*Additional Testing*
The issue persists across different configurations:
- With --verbose flag: Same error
- With --format Json: Same error  
- With --format Table: Same error (default)

*Impact*
Users cannot retrieve or manage ReportBatchJob entities via the CLI, blocking any automation or scripting that depends on this entity type.

*Entity Type*
ReportBatchJob is listed as one of the 119 supported entity types in the CLI help documentation.
"@
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

Write-Host "Request Body:"
Write-Host $body

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $body
    Write-Host "Success! Created issue: $($response.key)" -ForegroundColor Green
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
