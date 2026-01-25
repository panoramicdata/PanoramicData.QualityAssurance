<#
.SYNOPSIS
    Quick JIRA search that outputs to file (avoids terminal buffer issues).

.DESCRIPTION
    Performs a JIRA JQL search and saves results to a file.
    
    LESSONS LEARNED:
    - Console output with large datasets corrupts terminal buffer
    - Always save to file for reliable results
    - Use simple JQL - component filters fail if component doesn't exist
    - REST API directly is more flexible than JIRA.ps1 for complex queries

.PARAMETER JQL
    JQL query string. Default: Ready for Test tickets

.PARAMETER MaxResults
    Maximum results. Default: 50

.PARAMETER OutputPath
    Output file path. Default: jira-search-results.json

.PARAMETER Format
    Output format: json or table. Default: json

.EXAMPLE
    .\Search-Jira.ps1 -JQL "project=MS AND status='In Progress'"
    .\Search-Jira.ps1 -JQL "project=MS AND labels=CLI" -Format table

.NOTES
    Requires: $env:JIRA_USERNAME and $env:JIRA_PASSWORD
#>

param(
    [string]$JQL = "project=MS AND status='Ready for Test' ORDER BY updated DESC",
    [int]$MaxResults = 50,
    [string]$OutputPath = "jira-search-results.json",
    [ValidateSet("json", "table")]
    [string]$Format = "json"
)

if (-not $env:JIRA_USERNAME -or -not $env:JIRA_PASSWORD) {
    Write-Error "Missing JIRA credentials. Set `$env:JIRA_USERNAME and `$env:JIRA_PASSWORD"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{ 
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json" 
}

$body = @{ 
    jql = $JQL
    maxResults = $MaxResults
    fields = @("summary", "issuetype", "labels", "fixVersions", "updated", "status", "assignee", "priority") 
} | ConvertTo-Json

Write-Host "Searching: $JQL" -ForegroundColor Cyan

try {
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/search" -Method POST -Headers $headers -Body $body
} catch {
    Write-Error "JIRA API failed: $_"
    exit 1
}

Write-Host "Found: $($result.total) total ($($result.issues.Count) returned)" -ForegroundColor Green

if ($Format -eq "json") {
    # Save raw JSON for programmatic use
    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
} else {
    # Save as readable table
    $tableOutput = $result.issues | ForEach-Object {
        $labels = if ($_.fields.labels) { $_.fields.labels -join "," } else { "-" }
        $version = if ($_.fields.fixVersions -and $_.fields.fixVersions.Count -gt 0) { 
            ($_.fields.fixVersions | Select-Object -First 1).name 
        } else { "-" }
        $assignee = if ($_.fields.assignee) { $_.fields.assignee.displayName } else { "Unassigned" }
        
        "$($_.key)`t$($_.fields.issuetype.name)`t$($_.fields.summary)`t$labels`t$version`t$assignee"
    }
    
    @("Key`tType`tSummary`tLabels`tVersion`tAssignee") + $tableOutput | Out-File -FilePath $OutputPath -Encoding UTF8
}

Write-Host "Saved to: $OutputPath" -ForegroundColor Green
