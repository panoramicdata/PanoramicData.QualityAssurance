# Create JIRA feature request for schedule/batch job execution

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
The MagicSuite CLI currently only supports CRUD operations (get, get-by-id, patch, delete) but lacks the ability to execute or trigger schedules and batch jobs. This limits automation capabilities and forces users to either use the web UI or make direct REST API calls.

*Current Limitation*
The CLI provides access to the following entity types but no execution commands:
- ReportSchedule
- ReportBatchJob
- Job
- DataMagicSync

Users can view, update, and delete these entities but cannot trigger their execution from the command line.

*Requested Features*

1. *Execute Report Schedules*
   Add ability to manually trigger a report schedule:
   {code}
   magicsuite api execute reportschedule <id>
   magicsuite schedule run <id>
   {code}

2. *Run Batch Jobs*
   Add ability to execute a report batch job:
   {code}
   magicsuite api execute reportbatchjob <id>
   magicsuite batch run <id>
   {code}

3. *Trigger Jobs*
   Add ability to create and execute generic jobs:
   {code}
   magicsuite api execute job <id>
   magicsuite job run <id>
   {code}

4. *Execute Data Syncs*
   Add ability to trigger DataMagic syncs:
   {code}
   magicsuite api execute datamagicsync <id>
   magicsuite sync run <id>
   {code}

*Use Cases*

1. *Automation Scripts*
   - Scheduled PowerShell scripts that trigger report generation
   - CI/CD pipelines that run batch jobs after deployments
   - Automated data sync operations on schedule

2. *Testing and Development*
   - Quickly test schedules without waiting for scheduled time
   - Verify batch job configurations
   - Test report generation with different parameters

3. *Operations and Troubleshooting*
   - Manually trigger failed schedules for retry
   - Run batch jobs on-demand for urgent reports
   - Execute syncs during maintenance windows

*Suggested Command Structure*

Option 1: Generic execute command under api
{code}
magicsuite api execute <entity-type> <id> [options]
magicsuite api execute reportschedule 123
magicsuite api execute reportbatchjob 456 --wait
{code}

Option 2: Dedicated top-level commands
{code}
magicsuite schedule run <id> [options]
magicsuite batch run <id> [options]
magicsuite sync run <id> [options]
{code}

*Additional Options*
- --wait: Wait for execution to complete before returning
- --timeout <seconds>: Maximum time to wait
- --parameters <json>: Pass runtime parameters
- --format json: Return execution results in JSON format

*Benefits*
- Enables full automation without web UI dependency
- Consistent with CLI design principles (command-line first)
- Reduces need for custom REST API scripts
- Improves developer and operations experience
- Supports DevOps and CI/CD workflows

*Priority*
High - This is a significant gap in CLI functionality that limits its usefulness for automation scenarios.
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Task" }
        summary = "MagicSuite CLI: Add ability to execute/run schedules, batch jobs, and syncs"
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating JIRA feature request ticket..." -ForegroundColor Cyan

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
