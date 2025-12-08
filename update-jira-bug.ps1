# Update JIRA issue MS-22521 with full description

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
The 'magicsuite api get reportbatchjobs' command throws a null reference exception and fails to retrieve any data.

*Environment*
- MagicSuite CLI Version: 3.28.258+b2ef011bc7
- Installation Path: C:\Users\amycb\.dotnet\tools\magicsuite.exe
- Date Tested: December 2, 2025

*Steps to Reproduce*
1. Run command: {{magicsuite api get reportbatchjobs}}
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
- With {{--verbose}} flag: Same error
- With {{--format Json}}: Same error  
- With {{--format Table}}: Same error (default)

*Impact*
Users cannot retrieve or manage ReportBatchJob entities via the CLI, blocking any automation or scripting that depends on this entity type.

*Entity Type*
ReportBatchJob is listed as one of the 119 supported entity types in the CLI help documentation.
"@

$body = @{
    fields = @{
        description = $description
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22521" -Method PUT -Headers $headers -Body $body
    Write-Host "Success! Updated issue MS-22521" -ForegroundColor Green
}
catch {
    Write-Host "Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
